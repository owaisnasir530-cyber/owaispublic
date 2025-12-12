#!/bin/bash

# ================================================
# Instagram Bot - Status Monitor
# ================================================
# Quick status check for bot progress

BOT_DIR="/root/ig-engagement-bot"  # Change to your actual directory
cd "$BOT_DIR" || exit 1

echo "╔════════════════════════════════════════╗"
echo "║   Instagram Bot Status Dashboard      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Current Date
echo "📅 Current Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Daily Stats
echo "📊 Today's Statistics:"
if [ -f "data/daily_stats.json" ]; then
    cat data/daily_stats.json | python3 -m json.tool 2>/dev/null || cat data/daily_stats.json
else
    echo "   No stats file yet (bot hasn't run today)"
fi
echo ""

# Progress Tracking
echo "📈 Overall Progress:"
if [ -f "data/targets.csv" ]; then
    TOTAL=$(wc -l < data/targets.csv)
    if [ -f "data/followed.csv" ]; then
        DONE=$(wc -l < data/followed.csv)
    else
        DONE=0
    fi
    REMAINING=$((TOTAL - DONE))
    PERCENT=$((DONE * 100 / TOTAL))
    
    echo "   Total Targets: $TOTAL"
    echo "   Processed: $DONE ($PERCENT%)"
    echo "   Remaining: $REMAINING"
    
    # Progress bar
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    printf "   ["
    printf "%0.s█" $(seq 1 $FILLED)
    printf "%0.s░" $(seq 1 $EMPTY)
    printf "] $PERCENT%%\n"
else
    echo "   No targets.csv found"
fi
echo ""

# DM Status
echo "💬 DM Queue Status:"
if [ -f "data/followed.csv" ]; then
    # Count profiles ready for DM (7+ days old, no DM sent)
    SEVEN_DAYS_AGO=$(($(date +%s) - 604800))
    READY_FOR_DM=$(awk -F',' -v cutoff="$SEVEN_DAYS_AGO" '
        $2 != "" && $2 < cutoff*1000 && $3 != "true" {count++} 
        END {print count+0}
    ' data/followed.csv)
    
    DM_SENT=$(grep -c ",true$" data/followed.csv 2>/dev/null || echo "0")
    
    echo "   DMs Sent Total: $DM_SENT"
    echo "   Ready for DM (7+ days): $READY_FOR_DM"
else
    echo "   No followed.csv yet"
fi
echo ""

# Recent Activity
echo "📝 Recent Activity (Last 5 actions):"
if [ -f "logs/bot_$(date +%Y%m%d).log" ]; then
    grep -E "Followed|Commented|DM sent" logs/bot_$(date +%Y%m%d).log | tail -5
else
    echo "   No activity logged today"
fi
echo ""

# Check for Errors
echo "⚠️  Recent Errors/Warnings:"
if [ -f "logs/bot_$(date +%Y%m%d).log" ]; then
    ERROR_COUNT=$(grep -ic "error\|blocked\|failed" logs/bot_$(date +%Y%m%d).log || echo "0")
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "   ⚠️  Found $ERROR_COUNT errors today!"
        grep -i "error\|blocked\|failed" logs/bot_$(date +%Y%m%d).log | tail -3
    else
        echo "   ✅ No errors detected today"
    fi
else
    echo "   No log file for today"
fi
echo ""

# Next Scheduled Run
echo "⏰ Next Scheduled Run:"
NEXT_RUN=$(crontab -l 2>/dev/null | grep "run_bot_automated.sh" | grep -v "^#")
if [ -n "$NEXT_RUN" ]; then
    echo "   Cron: $NEXT_RUN"
else
    echo "   ⚠️  No cron job found!"
fi
echo ""

# Estimated Completion
if [ -f "data/targets.csv" ] && [ -f "data/daily_stats.json" ]; then
    REMAINING=$((TOTAL - DONE))
    if [ "$REMAINING" -gt 0 ]; then
        DAYS_LEFT=$((REMAINING / 40 + 1))
        COMPLETION_DATE=$(date -d "+$DAYS_LEFT days" +%Y-%m-%d)
        echo "🎯 Estimated Completion: $COMPLETION_DATE (~$DAYS_LEFT days)"
    else
        echo "🎉 All targets processed!"
    fi
fi

echo ""
echo "════════════════════════════════════════"