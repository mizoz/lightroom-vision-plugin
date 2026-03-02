#!/bin/bash

# Lightroom Vision Plugin - Installation Script

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Lightroom Vision Plugin - Installation             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is required but not installed."
    echo "   Install from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js: $(node --version)"

# Install Vision Service
echo ""
echo "📦 Installing Vision Service..."
cd ~/AZ-Projects/lightroom-vision-service
npm install --silent

# Check for .env file
if [ ! -f .env ]; then
    echo ""
    echo "⚠️  Configuration needed!"
    echo ""
    echo "1. Copy the example config:"
    echo "   cp .env.example .env"
    echo ""
    echo "2. Edit .env and add your Alibaba Cloud Coding Plan API key:"
    echo "   ALIBABA_API_KEY=sk-sp-xxxxx"
    echo ""
    echo "3. Get your API key from:"
    echo "   https://modelstudio.console.alibabacloud.com/"
    echo ""
    echo "4. Then start the service:"
    echo "   npm start"
else
    echo "✅ Configuration found (.env)"
fi

# Install Lightroom Plugin
echo ""
echo "📦 Lightroom Plugin ready to install"
echo ""
echo "To install in Lightroom Classic:"
echo "1. Open Lightroom Classic"
echo "2. File → Plug-in Manager"
echo "3. Click 'Add' and select:"
echo "   ~/AZ-Projects/lightroom-vision-plugin/lightroomvisionplugin.lrplugin"
echo ""

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Installation Complete!                             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Configure .env with your API key"
echo "2. Start the Vision Service: npm start"
echo "3. Install plugin in Lightroom (see above)"
echo ""
