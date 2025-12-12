#!/bin/bash

# ================================================
# Instagram Bot - Quick Installation Script
# ================================================
# Run this once to set up everything automatically

echo "╔════════════════════════════════════════╗"
echo "║  Instagram Bot - Quick Setup          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get the current directory
INSTALL_DIR=$(pwd)
echo "📁 Installing in: $INSTALL_DIR"
echo ""

# Step 1: Create necessary directories
echo "📦 Creating directories..."
mkdir -p data
mkdir -p logs
mkdir -p errorScreenshots
echo "   ✅ Directories created"
echo ""

# Step 2: Make scripts executable
echo "🔧 Setting permissions..."
chmod +x run_bot_automated.sh 2>/dev/null
chmod +x check_status.sh 2>/dev/null
chmod +x *.bat 2>/dev/null
echo "   ✅ Permissions set"
echo ""

# Step 3: Check for Node.js
echo "🔍 Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js found: $NODE_VERSION"
else
    echo "   ❌ Node.js not found!"
    echo ""
    echo "Please install Node.js first:"
    echo "   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "   sudo apt-get install -y nodejs"
    exit 1
fi
echo ""

# Step 4: Install npm dependencies
echo "📦 Installing npm packages..."
if [ -f "package.json" ]; then
    npm install
    echo "   ✅ Dependencies installed"
else
    echo "   ℹ️  No package.json found, installing manually..."
    npm install playwright csv-parser
    echo "   ✅ Playwright and csv-parser installed"
fi
echo ""

# Step 5: Install Playwright browsers
echo "🌐 Installing Playwright browsers..."
npx playwright install chromium
echo "   ✅ Chromium installed"
echo ""

# Step 6: Create empty CSV files if they don't exist
echo "📄 Setting up CSV files..."
if [ ! -f "data/targets.csv" ]; then
    echo "username" > data/targets.csv
    echo "   ✅ Created data/targets.csv (add your usernames here)"
else
    echo "   ✅ data/targets.csv already exists"
fi

if [ ! -f "data/followed.csv" ]; then
    touch data/followed.csv
    echo "   ✅ Created data/followed.csv"
else
    echo "   ✅ data/followed.csv already exists"
fi
echo ""

# Step 7: Update paths in automation script
echo "🔧 Configuring automation script..."
sed -i "s|BOT_DIR=\".*\"|BOT_DIR=\"$INSTALL_DIR\"|g" run_bot_automated.sh 2>/dev/null
sed -i "s|BOT_DIR=\".*\"|BOT_DIR=\"$INSTALL_DIR\"|g" check_status.sh 2>/dev/null
echo "   ✅ Paths configured"
echo ""

# Step 8: Check if session.json exists
echo "🔐 Checking authentication..."
if [ -f "data/session.json" ]; then
    echo "   ✅ Session file found"
else
    echo "   ⚠️  No session.json found"
    echo "   Run: node main_login.js to login first"
fi
echo ""

# Step 9: Test run (optional)
echo "🧪 Ready to test?"
read -p "   Do you want to run a test now? (y/n): " RUN_TEST

if [ "$RUN_TEST" = "y" ] || [ "$RUN_TEST" = "Y" ]; then
    echo ""
    echo "Running test..."
    node follow_comment_bot.js
fi
echo ""

# Step 10: Setup cron job
echo "⏰ Setting up automation..."
read -p "   Do you want to set up daily automation? (y/n): " SETUP_CRON

if [ "$SETUP_CRON" = "y" ] || [ "$SETUP_CRON" = "Y" ]; then
    echo ""
    echo "Choose automation schedule:"
    echo "1) Once daily at 10 AM UTC"
    echo "2) Twice daily at 10 AM and 6 PM UTC"
    echo "3) Every 12 hours"
    echo "4) Custom (manual setup)"
    read -p "Enter choice (1-4): " CRON_CHOICE
    
    case $CRON_CHOICE in
        1)
            CRON_LINE="0 10 * * * $INSTALL_DIR/run_bot_automated.sh"
            ;;
        2)
            CRON_LINE="0 10,18 * * * $INSTALL_DIR/run_bot_automated.sh"
            ;;
        3)
            CRON_LINE="0 */12 * * * $INSTALL_DIR/run_bot_automated.sh"
            ;;
        *)
            echo "Skipping automatic cron setup"
            CRON_LINE=""
            ;;
    esac
    
    if [ -n "$CRON_LINE" ]; then
        # Add to crontab
        (crontab -l 2>/dev/null | grep -v "run_bot_automated.sh"; echo "$CRON_LINE") | crontab -
        echo "   ✅ Cron job added: $CRON_LINE"
    fi
fi
echo ""

# Final Summary
echo "╔════════════════════════════════════════╗"
echo "║         Installation Complete!        ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Login to Instagram:"
echo "   node main_login.js"
echo ""
echo "2. Add usernames to data/targets.csv"
echo ""
echo "3. Test with a few profiles:"
echo "   node follow_comment_bot.js"
echo ""
echo "4. Check status anytime:"
echo "   ./check_status.sh"
echo ""
echo "5. View logs:"
echo "   tail -f logs/bot_$(date +%Y%m%d).log"
echo ""
echo "6. View cron jobs:"
echo "   crontab -l"
echo ""
echo "🎉 Bot will now run automatically!"
echo ""