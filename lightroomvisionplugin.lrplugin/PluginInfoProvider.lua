local LrView = import 'LrView'
local LrPrefs = import 'LrPrefs'
local LrBinding = import 'LrBinding'

local prefs = LrPrefs.prefsForPlugin()

-- Set defaults
if prefs.metadataField == nil then
    prefs.metadataField = "caption"
end

if prefs.skipExisting == nil then
    prefs.skipExisting = false
end

if prefs.promptType == nil then
    prefs.promptType = "alt_text"
end

return {
    sectionsForTopOfDialog = function(f)
        local bind = LrView.bind
        local share = LrView.share

        return {
            {
                title = "Vision Analyzer Settings",
                f:column {
                    f:row {
                        f:static_text {
                            title = "Save results to:",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:popup_menu {
                            value = bind { key = 'metadataField', object = prefs },
                            items = {
                                { title = "Caption", value = "caption" },
                                { title = "Headline", value = "headline" },
                                { title = "Title", value = "title" },
                                { title = "Description", value = "description" },
                            },
                        },
                    },
                    f:row {
                        f:static_text {
                            title = "Analysis type:",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:popup_menu {
                            value = bind { key = 'promptType', object = prefs },
                            items = {
                                { title = "Alt Text (Accessibility)", value = "alt_text" },
                                { title = "Keywords (Search)", value = "keywords" },
                                { title = "Caption", value = "caption" },
                                { title = "Full Analysis", value = "detailed" },
                            },
                        },
                    },
                    f:row {
                        f:static_text {
                            title = "",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:checkbox {
                            title = "Skip photos that already have metadata",
                            value = bind { key = 'skipExisting', object = prefs },
                        },
                    },
                    f:row {
                        f:static_text {
                            title = "",
                            alignment = 'right',
                            width = share 'label_width',
                        },
                        f:static_text {
                            title = "Keywords are always saved to the Keywords field",
                            font = "<system>",
                            width = 300,
                        },
                    },
                },
            },
        }
    end,
}
