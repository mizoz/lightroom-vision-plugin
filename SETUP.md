# Complete Setup Guide

> End-to-end instructions for Lightroom Vision — from API key to first photo analysis.

## Overview

Lightroom Vision consists of two components:

| Component | Purpose | Location |
|-----------|---------|----------|
| **Vision Service** | HTTP server, API integration, caching | [lightroom-vision-service](https://github.com/mizoz/lightroom-vision-service) |
| **Vision Plugin** | Lightroom UI, photo processing | [lightroom-vision-plugin](https://github.com/mizoz/lightroom-vision-plugin) |

**Why two components?** Security. The plugin has **no API key** — the service holds it securely.

---

## Step 1: Get Alibaba Cloud API Key

### 1.1 Create Account

1. Go to [Alibaba Cloud](https://www.alibabacloud.com/)
2. Sign up (requires email, phone verification)
3. Complete identity verification

### 1.2 Subscribe to Coding Plan

1. Go to [Model Studio Console](https://modelstudio.console.alibabacloud.com/)
2. Click **Subscription Plans** in left sidebar
3. Select **Coding Plan Lite**
4. Complete purchase ($3 first month, $5/month after)

**Why Coding Plan?**
- Compliant with Alibaba's terms (this service qualifies as a "coding tool")
- Predictable pricing (no surprise bills)
- Access to Qwen-VL, Kimi-K2.5 vision models

### 1.3 Get Your API Key

1. Go to [Coding Plan Page](https://modelstudio.console.alibabacloud.com/ap-southeast-1/?tab=globalset#/efm/coding_plan)
2. Copy your API key (format: `sk-sp-xxxxx`)
3. **Save it securely** — you'll need it in Step 2

---

## Step 2: Install Vision Service

### 2.1 Clone & Install

```bash
cd ~/AZ-Projects
git clone https://github.com/mizoz/lightroom-vision-service.git
cd lightroom-vision-service
npm install
```

### 2.2 Configure

```bash
cp .env.example .env
nano .env
```

Edit `.env`:

```env
# Your API key from Step 1
ALIBABA_API_KEY=sk-sp-xxxxx

# Coding Plan endpoint (don't change)
ALIBABA_BASE_URL=https://coding-intl.dashscope.aliyuncs.com/apps/anthropic

# Vision model (qwen3.5-plus or kimi-k2.5)
VISION_MODEL=qwen3.5-plus

# Service port (default: 3456)
PORT=3456

# Debug logging (true/false)
DEBUG=false
```

**⚠️ Security Note:** Never commit `.env` to git. It's in `.gitignore` by default.

### 2.3 Start Service

```bash
npm start
```

You should see:

```
╔════════════════════════════════════════════════════════╗
║     Lightroom Vision Service                           ║
║     Running on http://localhost:3456                   ║
║                                                        ║
║     Endpoints:                                         ║
║     GET  /health          - Health check               ║
║     POST /api/v1/analyze  - Single image analysis      ║
║     POST /api/v1/analyze/batch - Batch analysis        ║
║     GET  /api/v1/stats    - Usage statistics           ║
║     DELETE /api/v1/cache  - Clear cache                ║
╚════════════════════════════════════════════════════════╝
```

### 2.4 Verify

```bash
curl http://localhost:3456/health
```

Expected response:

```json
{
  "status": "healthy",
  "timestamp": "2026-03-02T20:30:00.000Z",
  "version": "1.0.0"
}
```

**Leave this terminal running.** The service must be active for the plugin to work.

---

## Step 3: Install Lightroom Plugin

### 3.1 Clone Plugin

```bash
cd ~/AZ-Projects
git clone https://github.com/mizoz/lightroom-vision-plugin.git
```

### 3.2 Install in Lightroom

1. Open **Lightroom Classic**
2. Go to **File → Plug-in Manager**
3. Click **Add** button (bottom left)
4. Navigate to `~/AZ-Projects/lightroom-vision-plugin/`
5. Select the `lightroomvisionplugin.lrplugin` folder
6. Click **Choose**

Plugin appears in "Installed Plug-ins" list.

### 3.3 Configure Plugin

In Plug-in Manager, with "Vision Analyzer" selected:

| Setting | Value | Why |
|---------|-------|-----|
| Save results to | Caption | Standard field for descriptions |
| Analysis type | Alt Text | Accessibility focus |
| Skip existing | Yes | Saves API quota |

Click **Done**.

---

## Step 4: Test It

### 4.1 Select a Photo

1. Go to **Library** module
2. Select any photo

### 4.2 Run Analysis

1. **Library → Plug-in Extras → Generate Alt Text**
2. Wait 3-5 seconds
3. Progress bar completes

### 4.3 Verify Results

1. Open **Metadata** panel (right sidebar)
2. Look for **Caption** field
3. You should see AI-generated alt text

Example output:

> "A person hiking on a rocky mountain trail with snow-capped peaks in the background, blue sky with scattered clouds."

---

## Step 5: Daily Use

### Starting Your Session

```bash
# Terminal 1: Start service
cd ~/AZ-Projects/lightroom-vision-service
npm start
```

Leave running. Then open Lightroom normally.

### Processing Photos

| Task | Steps |
|------|-------|
| Single photo | Select → Library → Plug-in Extras → Generate Alt Text |
| Batch (collection) | Select all → Same menu → Wait for progress |
| Keywords only | Select → Extract Keywords |
| Full metadata | Select → Full Analysis |

### Stopping Service

When done:

```bash
# In service terminal
Ctrl+C
```

Or leave running — minimal resource usage when idle.

---

## Monitoring & Maintenance

### Check Usage

```bash
curl http://localhost:3456/api/v1/stats
```

Response:

```json
{
  "today": {
    "requests": 47,
    "cache_hits": 35,
    "cache_hit_rate": "74.5%",
    "avg_processing_time_ms": 2890
  },
  "cache": {
    "total_cached": 312
  }
}
```

### Clear Old Cache

```bash
# Remove entries older than 7 days
curl -X DELETE "http://localhost:3456/api/v1/cache?olderThanDays=7"
```

### Update Components

```bash
# Service
cd ~/AZ-Projects/lightroom-vision-service
git pull
npm install  # if new dependencies
npm start

# Plugin
cd ~/AZ-Projects/lightroom-vision-plugin
git pull
# Restart Lightroom
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check Node version (need 18+)
node --version

# Check port availability
netstat -tlnp | grep 3456

# Check .env exists
ls -la .env
```

### "Vision Service Unreachable" in Lightroom

1. Verify service is running:
   ```bash
   curl http://localhost:3456/health
   ```
2. Check firewall isn't blocking localhost
3. Restart service

### No Results After Analysis

1. Check plugin logs:
   - **File → Plug-in Manager → [Vision Analyzer] → Logs**
2. Check service logs for API errors
3. Verify API key is valid (Coding Plan, not pay-as-you-go)

### API Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Invalid API key | Wrong format | Verify `sk-sp-xxxxx` |
| Wrong endpoint | Using pay-as-you-go URL | Use Coding Plan URL |
| Quota exceeded | Monthly limit reached | Wait or upgrade plan |
| Model unavailable | Model not in your plan | Use `qwen3.5-plus` or `kimi-k2.5` |

---

## Security Best Practices

### Do ✅

- Keep `.env` file secure (chmod 600)
- Rotate API key periodically
- Run service on localhost only
- Monitor usage via `/api/v1/stats`

### Don't ❌

- Never commit `.env` to git
- Never share API key
- Never expose service to network
- Never log sensitive data

---

## Cost Management

### Coding Plan Lite Quota

| Period | Requests | Cost |
|--------|----------|------|
| First month | 18,000 | $3 |
| Renewal | 18,000 | $5/month |

### Real-World Usage

| User Type | Photos/Month | Quota Used | Cost/Month |
|-----------|--------------|------------|------------|
| Light | 500 | ~5% | $5 |
| Moderate | 2,000 | ~20% | $5 |
| Heavy | 5,000 | ~50% | $5 |
| Pro | 10,000+ | 100%+ | Upgrade needed |

**With caching:** 80-90% reduction in API calls for similar photos (bursts, duplicates).

---

## Architecture Deep Dive

### Data Flow

```
1. User selects photo in Lightroom
2. Plugin exports photo to temp (1024x1024 JPEG)
3. Plugin base64-encodes image
4. Plugin POSTs to localhost:3456/api/v1/analyze
5. Service hashes image, checks cache
6. If cache miss: Service calls Alibaba API
7. Service stores result in SQLite cache
8. Service returns alt text + keywords
9. Plugin saves to Lightroom metadata
10. Temp file deleted
```

### Caching Strategy

| Component | What's Cached | Key |
|-----------|---------------|-----|
| Image hash | SHA256 of base64 | `image_hash` |
| Result | Alt text, keywords | `image_hash + prompt_type` |
| Usage | Request count, duration | Timestamp |

Cache location: `~/AZ-Projects/lightroom-vision-service/data/vision-cache.db`

### Security Boundaries

```
┌────────────────────────────────────────────────┐
│  Lightroom Plugin (Untrusted)                  │
│  - No API key                                  │
│  - Localhost-only communication                │
└───────────────────┬────────────────────────────┘
                    │ (localhost:3456)
                    ▼
┌────────────────────────────────────────────────┐
│  Vision Service (Trusted)                      │
│  - Holds API key (.env)                        │
│  - Validates all input                         │
│  - Sanitizes all logs                          │
└───────────────────┬────────────────────────────┘
                    │ (HTTPS)
                    ▼
┌────────────────────────────────────────────────┐
│  Alibaba Cloud API (External)                  │
│  - Coding Plan endpoint                        │
│  - Rate limited                                │
│  - Quota tracked                               │
└────────────────────────────────────────────────┘
```

---

## Next Steps

1. ✅ Process your first batch of photos
2. ✅ Configure your preferred metadata fields
3. ✅ Set up monitoring (check stats weekly)
4. ✅ Share feedback or issues on GitHub

---

## Support

- **Issues:** [Vision Service](https://github.com/mizoz/lightroom-vision-service/issues) or [Plugin](https://github.com/mizoz/lightroom-vision-plugin/issues)
- **Docs:** README files in each repo
- **Alibaba Docs:** [Model Studio](https://www.alibabacloud.com/help/en/model-studio)

---

## License

MIT — Both components are open source.
