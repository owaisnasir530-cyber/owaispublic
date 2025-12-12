#!/bin/bash

# ================================================
# Instagram Bot - Daily Automation Script
# ================================================
# This script runs the bot once per day automatically
# and logs everything for monitoring

BOT_DIR="/root/ig-engagement-bot"  # Change this to your actual bot directory
LOG_DIR="$BOT_DIR/logs"
ERROR_DIR="$BOT_DIR/errorScreenshots"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$ERROR_DIR"

# Log file with date
LOG_FILE="$LOG_DIR/bot_$(date +%Y%m%d).log"

echo "========================================" >> "$LOG_FILE"
echo "Bot Run Started: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Change to bot directory
cd "$BOT_DIR" || exit 1

# Run the bot and capture output
node follow_comment_bot.js >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

echo "========================================" >> "$LOG_FILE"
echo "Bot Run Completed: $(date)" >> "$LOG_FILE"
echo "Exit Code: $EXIT_CODE" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Keep only last 30 days of logs
find "$LOG_DIR" -name "bot_*.log" -mtime +30 -delete

exit $EXIT_CODE