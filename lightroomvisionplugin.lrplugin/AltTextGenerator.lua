local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrHttp = import 'LrHttp'
local LrFileUtils = import 'LrFileUtils'
local LrExportSession = import 'LrExportSession'
local LrStringUtils = import 'LrStringUtils'
local LrPathUtils = import 'LrPathUtils'
local LrPrefs = import 'LrPrefs'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrLogger = import 'LrLogger'

local logger = LrLogger('VisionPlugin')
logger:enable("logfile")

local configPath = LrPathUtils.child(_PLUGIN.path, 'config.lua')
local config = dofile(configPath)
local prefs = LrPrefs.prefsForPlugin()
local dkjsonPath = LrPathUtils.child(_PLUGIN.path, 'dkjson.lua')
local json = dofile(dkjsonPath)

local function resizePhoto(photo, progressScope)
    progressScope:setCaption("Resizing photo...")
    local tempDir = LrPathUtils.getStandardFilePath('temp')
    local photoName = LrPathUtils.leafName(photo:getFormattedMetadata('fileName'))
    local resizedPhotoPath = LrPathUtils.child(tempDir, photoName)

    if LrFileUtils.exists(resizedPhotoPath) then
        LrFileUtils.delete(resizedPhotoPath)
    end

    local exportSettings = {
        LR_export_destinationType = 'specificFolder',
        LR_export_destinationPathPrefix = tempDir,
        LR_export_useSubfolder = false,
        LR_format = 'JPEG',
        LR_jpeg_quality = 0.8,
        LR_minimizeEmbeddedMetadata = true,
        LR_outputSharpeningOn = false,
        LR_size_doConstrain = true,
        LR_size_maxHeight = 1024,
        LR_size_maxWidth = 1024,
        LR_size_resizeType = 'wh',
        LR_size_units = 'pixels',
    }

    local exportSession = LrExportSession({
        photosToExport = {photo},
        exportSettings = exportSettings
    })

    for _, rendition in exportSession:renditions() do
        local success, path = rendition:waitForRender()
        if success then
            return path
        end
    end

    return nil
end

local function encodePhotoToBase64(filePath, progressScope)
    progressScope:setCaption("Encoding photo...")

    local file = io.open(filePath, "rb")
    if not file then
        return nil
    end

    local data = file:read("*all")
    file:close()

    return LrStringUtils.encodeBase64(data)
end

local function requestAnalysisFromService(imageBase64, promptType, progressScope)
    progressScope:setCaption("Analyzing with vision model...")

    local url = config.SERVICE_URL .. "/api/v1/analyze"
    local headers = {
        { field = "Content-Type", value = "application/json" },
    }

    local body = {
        image = imageBase64,
        promptType = promptType or "alt_text",
        useCache = true
    }

    local bodyJson = json.encode(body)
    local response, status = LrHttp.post(url, bodyJson, headers)

    if not response then
        return nil, "No response from Vision Service (is it running?)"
    end

    local ok, decoded = pcall(json.decode, response)
    if not ok then
        logger:trace("Failed to parse service response: " .. response)
        return nil, "Invalid response from Vision Service"
    end

    if not decoded.success then
        logger:trace("Service error: " .. (decoded.error or "Unknown error"))
        return nil, decoded.error or "Vision Service error"
    end

    return decoded.data, nil
end

local function analyzePhoto(photo, promptType, progressScope)
    local metadataField = prefs.metadataField or "caption"

    local resizedFilePath = resizePhoto(photo, progressScope)
    if not resizedFilePath then
        return false, "Failed to resize photo"
    end

    local base64Image = encodePhotoToBase64(resizedFilePath, progressScope)
    LrFileUtils.delete(resizedFilePath)

    if not base64Image then
        return false, "Failed to encode photo"
    end

    local result, err = requestAnalysisFromService(base64Image, promptType, progressScope)

    if result then
        photo.catalog:withWriteAccessDo("Set Analysis Result", function()
            if result.alt_text and result.alt_text ~= "" then
                photo:setRawMetadata(metadataField, result.alt_text)
            end
            
            -- Also save keywords if available
            if result.keywords and #result.keywords > 0 then
                local keywordsStr = table.concat(result.keywords, ", ")
                photo:setRawMetadata("keywords", keywordsStr)
            end
        end)
        return true, result
    end

    return false, err or "Failed to analyze photo"
end

LrTasks.startAsyncTask(function()
    LrFunctionContext.callWithContext("GenerateAltText", function(context)
        local catalog = LrApplication.activeCatalog()
        local selectedPhotos = catalog:getTargetPhotos()

        if #selectedPhotos == 0 then
            LrDialogs.message("Please select at least one photo.")
            return
        end

        -- Check if service is reachable
        local testResponse, testStatus = LrHttp.get(config.SERVICE_URL .. "/health")
        if not testResponse then
            LrDialogs.message(
                "Vision Service Unreachable",
                "Cannot connect to " .. config.SERVICE_URL .. "\n\n" ..
                "Make sure the Lightroom Vision Service is running:\n" ..
                "cd ~/AZ-Projects/lightroom-vision-service && npm start\n\n" ..
                "See README.md for setup instructions."
            )
            return
        end

        local metadataField = prefs.metadataField or "caption"
        local skipExisting = prefs.skipExisting or false
        local promptType = prefs.promptType or "alt_text"

        local progressScope = LrProgressScope({
            title = "Vision Analysis",
            functionContext = context,
        })

        local successes = 0
        local failures = 0
        local skipped = 0
        local cached = 0
        local errors = {}

        for i, photo in ipairs(selectedPhotos) do
            if progressScope:isCanceled() then
                break
            end

            progressScope:setPortionComplete(i - 1, #selectedPhotos)

            local shouldSkip = false
            if skipExisting then
                local existing = photo:getFormattedMetadata(metadataField)
                if existing and existing ~= "" then
                    shouldSkip = true
                end
            end

            if shouldSkip then
                skipped = skipped + 1
            else
                local success, resultOrErr = analyzePhoto(photo, promptType, progressScope)
                if success then
                    successes = successes + 1
                    if resultOrErr and resultOrErr.cached then
                        cached = cached + 1
                    end
                else
                    failures = failures + 1
                    if resultOrErr then
                        errors[resultOrErr] = (errors[resultOrErr] or 0) + 1
                    end
                end
            end

            progressScope:setPortionComplete(i, #selectedPhotos)
        end

        progressScope:done()

        if progressScope:isCanceled() then
            local parts = {"Operation canceled."}
            if successes > 0 then
                table.insert(parts, successes .. " photo(s) completed before cancellation.")
            end
            LrDialogs.message(table.concat(parts, " "))
        else
            local parts = {}
            if successes > 0 then
                local cacheInfo = cached > 0 and " (" .. cached .. " from cache)" or ""
                table.insert(parts, successes .. " succeeded" .. cacheInfo)
            end
            if failures > 0 then
                table.insert(parts, failures .. " failed")
            end
            if skipped > 0 then
                table.insert(parts, skipped .. " skipped")
            end
            local summary = table.concat(parts, ", ") .. "."

            local errorDetails = {}
            for err, count in pairs(errors) do
                if count > 1 then
                    table.insert(errorDetails, err .. " (" .. count .. "x)")
                else
                    table.insert(errorDetails, err)
                end
            end
            if #errorDetails > 0 then
                summary = summary .. "\n\n" .. table.concat(errorDetails, "\n")
            end

            LrDialogs.message("Vision Analyzer", summary)
        end
    end)
end)
