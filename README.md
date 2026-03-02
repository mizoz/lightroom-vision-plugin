# Lightroom Vision Plugin

> AI-powered photo organization for Lightroom Classic. Generate alt text, keywords, and captions automatically.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lightroom SDK](https://img.shields.io/badge/Lightroom-SDK%206.0-blue.svg)](https://www.adobe.com/)

## 🔐 Security Architecture

This plugin is designed with a **zero-trust** approach to API keys:

```
┌─────────────────────────────────────────────────────────────────┐
│                    YOUR LOCAL MACHINE                           │
│                                                                 │
│  ┌──────────────┐         ┌─────────────────┐                  │
│  │   Lightroom  │ ──────▶ │  Vision Service │                  │
│  │   Plugin     │  :3456  │  (localhost)    │                  │
│  │  (NO KEY)    │         │  (HOLDS KEY)    │                  │
│  └──────────────┘         └────────┬────────┘                  │
│                                    │                            │
└────────────────────────────────────┼────────────────────────────┘
                                     │ HTTPS
                                     ▼
                          ┌─────────────────────┐
                          │  Alibaba Cloud      │
                          │  Coding Plan API    │
                          └─────────────────────┘
```

### Why This Design?

| Component | What It Does | Security Benefit |
|-----------|--------------|------------------|
| **Plugin** | UI + photo prep | No API key = nothing to steal |
| **Service** | Holds key, makes API calls | Key never leaves localhost |
| **Alibaba API** | Vision analysis | Coding Plan compliant |

### Security Checklist

- ✅ **No API key in plugin** — Key stays in service's `.env`
- ✅ **Localhost-only** — Plugin talks to `127.0.0.1:3456`
- ✅ **No external calls** — Plugin never touches the internet
- ✅ **No key logging** — Service sanitizes all logs
- ✅ **Git-safe** — Plugin repo contains no secrets

---

## Features

| Feature | Description | Saves To |
|---------|-------------|----------|
| **Generate Alt Text** | Accessibility-focused descriptions | Caption (default) |
| **Extract Keywords** | Search-optimized tags | Keywords field |
| **Full Analysis** | Alt text + keywords + caption | All fields |

### Additional Capabilities

- ✅ Batch processing (hundreds of photos at once)
- ✅ Smart caching (never re-process same photo)
- ✅ Progress tracking with cancel support
- ✅ Skip existing metadata (saves quota)
- ✅ Configurable metadata field mapping

---

## Installation

### Prerequisites

1. **Vision Service must be running**

   See [lightroom-vision-service](https://github.com/mizoz/lightroom-vision-service) for setup.

   ```bash
   # Quick check
   curl http://localhost:3456/health
   # Should return: {"status":"healthy",...}
   ```

2. **Lightroom Classic** (SDK 6.0+)

### Install Plugin

1. Open **Lightroom Classic**
2. Go to **File → Plug-in Manager**
3. Click **Add**
4. Navigate to and select the `lightroomvisionplugin.lrplugin` folder
5. Plugin appears in "Installed Plug-ins" list
6. Click **Done**

### Configure Plugin

In Plug-in Manager, select "Vision Analyzer" and configure:

| Setting | Options | Recommended |
|---------|---------|-------------|
| Save results to | Caption, Headline, Title, Description | Caption |
| Analysis type | Alt Text, Keywords, Caption, Full Analysis | Alt Text |
| Skip existing | Yes, No | Yes (saves quota) |

Click **Done** when finished.

---

## Usage

### Single Photo

1. Select a photo in Library view
2. Go to **Library → Plug-in Extras → Generate Alt Text**
3. Wait 3-5 seconds (first time) or <1s (cached)
4. Check results in Metadata panel

### Batch Processing

1. Select multiple photos (or entire collection)
2. **Library → Plug-in Extras → Generate Alt Text**
3. Progress bar shows status
4. Results saved automatically

### Menu Items

| Menu Item | Analysis Type | Best For |
|-----------|---------------|----------|
| Generate Alt Text | `alt_text` | Accessibility |
| Extract Keywords | `keywords` | Search/organization |
| Full Analysis | `detailed` | Complete metadata |

---

## Workflow Examples

### New Import Workflow

```
1. Import photos to collection
2. Select all (Cmd/Ctrl+A)
3. Library → Plug-in Extras → Full Analysis
4. Wait for completion
5. Review and edit as needed
```

### Smart Processing Strategy

| Tip | Benefit |
|-----|---------|
| Enable "Skip existing" | Don't waste quota on processed photos |
| Process in batches (50-100) | Manageable chunks, easy to review |
| Check cache stats regularly | Monitor efficiency |

---

## Performance

| Scenario | Time | API Calls |
|----------|------|-----------|
| First photo | 3-5 seconds | 1 |
| Cached photo | <1 second | 0 |
| 50 photos (new) | 3-5 minutes | ~50 |
| 50 photos (cached) | <1 minute | 0 |

### Quota Impact (Coding Plan Lite)

| Usage Level | Photos/Month | Quota Used |
|-------------|--------------|------------|
| Light | 500 | ~5% |
| Moderate | 2,000 | ~20% |
| Heavy | 5,000 | ~50% |

**With caching:** 80-90% reduction in API calls for similar photos.

---

## Troubleshooting

### "Vision Service Unreachable"

**Cause:** Service not running or wrong port.

**Fix:**
```bash
# Check service status
curl http://localhost:3456/health

# Start service if needed
cd ~/AZ-Projects/lightroom-vision-service
npm start
```

### No Results After Analysis

1. Check Lightroom plugin logs:
   - **File → Plug-in Manager → [Vision Analyzer] → Logs**
2. Verify service is responding:
   ```bash
   curl http://localhost:3456/health
   ```
3. Check service logs for API errors

### Slow Processing

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| All photos slow | Network issue | Check internet, API status |
| First slow, then fast | Normal (caching) | Working as designed |
| Random slowdowns | API rate limiting | Wait, process in smaller batches |

### Plugin Not Appearing

1. Verify `.lrplugin` folder is selected (not contents)
2. Restart Lightroom
3. Check **File → Plug-in Manager** for errors

---

## Metadata Fields

| Analysis Type | Primary Field | Secondary Field |
|---------------|---------------|-----------------|
| Alt Text | Caption | — |
| Keywords | — | Keywords |
| Caption | Headline | — |
| Full Analysis | Caption + Headline | Keywords |

Change target field in plugin settings (Plug-in Manager).

---

## Privacy

| Data Type | Stored Where | Retained |
|-----------|--------------|----------|
| Photos | Never stored | — |
| API responses | Service cache (SQLite) | Until cleared |
| Image hashes | Service cache | Until cleared |
| API key | Service `.env` | Permanent (user-managed) |

**Key points:**
- Photos are resized and base64-encoded for API call, then deleted
- Only hash + text results cached (not image data)
- All data stays on your machine
- No telemetry, no analytics

---

## Updates

### Manual Update

```bash
cd ~/AZ-Projects/lightroom-vision-plugin
git pull
# Restart Lightroom
```

### Check Version

In Plug-in Manager, select "Vision Analyzer" — version shown in info panel.

---

## Development

### Plugin Structure

```
lightroomvisionplugin.lrplugin/
├── Info.lua                 # Plugin metadata, menu items
├── config.lua               # Service endpoint config
├── AltTextGenerator.lua     # Main analysis logic
├── PluginInfoProvider.lua   # Settings UI
└── dkjson.lua               # JSON library (Apache 2.0)
```

### Modify Service Endpoint

Edit `config.lua`:

```lua
return {
  SERVICE_URL = "http://localhost:3456",  -- Change port if needed
  ...
}
```

---

## Related Projects

- [Vision Service](https://github.com/mizoz/lightroom-vision-service) — Backend API
- [Complete Setup Guide](https://github.com/mizoz/lightroom-vision-plugin/blob/main/SETUP.md) — End-to-end instructions

---

## License

MIT — See [LICENSE](LICENSE) for details.

---

## Credits

- Original concept inspired by [gesteves/lightroom-alt-text-plugin](https://github.com/gesteves/lightroom-alt-text-plugin)
- JSON library: [dkjson](https://dkolf.de/src/dkjson-lua.html) (David Kolf)
- Vision models: Alibaba Cloud Coding Plan (Qwen-VL, Kimi-K2.5)
