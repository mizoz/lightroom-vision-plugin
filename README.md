# Lightroom Vision Plugin

Lightroom Classic plugin that uses AI vision models (via local service) to generate alt text, keywords, and captions for your photos.

## Features

- **Generate Alt Text** - Accessibility-focused descriptions (saves to Caption field)
- **Extract Keywords** - Search-optimized tags (saves to Keywords field)
- **Write Captions** - Engaging photo captions (saves to Headline field)
- **Full Analysis** - Comprehensive breakdown (all fields)
- **Smart Caching** - Never re-process the same photo twice
- **Batch Processing** - Analyze hundreds of photos at once

## Architecture

This plugin works with the **Lightroom Vision Service** (local HTTP server):

```
┌──────────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│  Lightroom       │────▶│  Vision Service     │────▶│  Alibaba Cloud   │
│  Plugin          │     │  (localhost:3456)   │     │  Coding Plan API │
│  (no API key)    │     │  (holds API key)    │     │  (Qwen-VL/Kimi)  │
└──────────────────┘     └─────────────────────┘     └──────────────────┘
```

**Why this design?**
- API key never touches Lightroom (stays in service's `.env`)
- Compliant with Alibaba Coding Plan terms (service is the "coding tool")
- Central caching across all clients
- Easy model switching without plugin updates

## Installation

### Step 1: Set Up Vision Service

First, install and configure the Vision Service:

```bash
cd ~/AZ-Projects/lightroom-vision-service
npm install
cp .env.example .env
# Edit .env with your Alibaba API key
npm start
```

See [Vision Service README](../lightroom-vision-service/README.md) for details.

### Step 2: Install Plugin in Lightroom

1. Open Lightroom Classic
2. Go to **File → Plug-in Manager**
3. Click **Add** and select the `lightroomvisionplugin.lrplugin` folder
4. Plugin appears in "Installed Plug-ins" list

### Step 3: Configure Plugin

In Plug-in Manager, configure:

| Setting | Options | Recommendation |
|---------|---------|----------------|
| Save results to | Caption, Headline, Title, Description | Caption |
| Analysis type | Alt Text, Keywords, Caption, Full Analysis | Alt Text |
| Skip existing | Yes/No | Yes (saves API quota) |

Click **Done** when finished.

## Usage

### Generate Alt Text for Selected Photos

1. Select one or more photos in Library
2. Go to **Library → Plug-in Extras → Generate Alt Text**
3. Wait for progress indicator
4. Results saved to configured metadata field

### Extract Keywords

1. Select photos
2. **Library → Plug-in Extras → Extract Keywords**
3. Keywords saved to Keywords field (comma-separated)

### Full Analysis

1. Select photos
2. **Library → Plug-in Extras → Full Analysis**
3. Alt text → Caption, Keywords → Keywords field

## Workflow Tips

### Batch Processing New Imports

1. Import photos to a collection
2. Select all (Cmd/Ctrl+A)
3. Run "Full Analysis"
4. Review and edit as needed

### Smart Processing Strategy

- **Enable "Skip existing"** - Don't waste quota on already-processed photos
- **Process in batches** - 50-100 photos at a time
- **Review cache stats** - Check service stats for hit rate

### Quota Management

Coding Plan Lite quota:
- 1,200 requests per 5 hours
- 9,000 requests per week
- ~5-10 invocations per photo

**Tips:**
- One photo = ~1 request (with caching)
- Cache hit = 0 API calls
- Process similar photos together (cache helps with duplicates)

## Troubleshooting

### "Vision Service Unreachable"

The plugin can't connect to the local service.

**Fix:**
```bash
# Check service is running
curl http://localhost:3456/health

# Start service if needed
cd ~/AZ-Projects/lightroom-vision-service && npm start
```

### No Results After Analysis

1. Check Lightroom plug-in logs:
   - **File → Plug-in Manager → [Vision Analyzer] → Logs**
2. Verify service is responding:
   ```bash
   curl http://localhost:3456/health
   ```
3. Check service logs for errors

### Slow Processing

- First photo: ~3-5 seconds (API call)
- Cached photos: <1 second
- Batch of 100: ~5-10 minutes (rate-limited)

**Optimize:**
- Enable caching (default: on)
- Skip existing metadata
- Process in smaller batches

## Metadata Fields

| Analysis Type | Saves To | Description |
|---------------|----------|-------------|
| Alt Text | Caption (default) | Accessibility description |
| Keywords | Keywords | Search tags (comma-separated) |
| Caption | Headline | Engaging photo caption |
| Full Analysis | All fields | Complete metadata set |

Change target field in plugin settings.

## Privacy & Security

- **No cloud uploads** - Photos processed via API, not stored
- **Local caching** - Cache stays on your machine (SQLite)
- **No API key in plugin** - Key secured in service's `.env`
- **Localhost only** - Service doesn't accept external connections

## Performance

| Metric | Value |
|--------|-------|
| First photo | 3-5 seconds |
| Cached photo | <1 second |
| Batch (50 photos) | 3-5 minutes |
| Memory usage | ~50MB |
| Cache size | ~1KB per photo |

## Updates

Check for updates:
1. **File → Plug-in Manager**
2. Select "Vision Analyzer"
3. Click "Check for Updates" (if available)

Or manually:
```bash
cd ~/AZ-Projects/lightroom-vision-plugin
git pull
# Restart Lightroom
```

## License

MIT

## Related

- [Vision Service](../lightroom-vision-service) - Backend API service
- [Original Plugin](https://github.com/gesteves/lightroom-alt-text-plugin) - Inspiration
