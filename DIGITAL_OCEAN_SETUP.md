# Instagram Bot - Digital Ocean Automation Setup Guide

## 📋 Complete Setup Instructions

Follow these steps to set up the bot to run automatically on Digital Ocean.

---

## STEP 1: Upload Files to Digital Ocean

Upload these files to your Digital Ocean droplet:
```
/root/ig-engagement-bot/
├── follow_comment_bot.js          (the optimized version)
├── main_login.js                  (your existing login script)
├── run_bot_automated.sh           (the new automation script)
├── data/
│   ├── session.json              (created after login)
│   ├── targets.csv               (your 500 usernames)
│   ├── followed.csv              (will be auto-created)
│   └── daily_stats.json          (will be auto-created)
├── logs/                         (will be auto-created)
└── errorScreenshots/             (will be auto-created)
```

---

## STEP 2: SSH into Your Digital Ocean Droplet

```bash
ssh root@your-droplet-ip
```

---

## STEP 3: Navigate to Bot Directory

```bash
cd /root/ig-engagement-bot
```

---

## STEP 4: Make Automation Script Executable

```bash
chmod +x run_bot_automated.sh
```

---

## STEP 5: Test the Bot Manually First

Before automating, test with 5 profiles:

1. Edit targets.csv with only 5 test usernames
2. Run manually:
```bash
node follow_comment_bot.js
```

3. Watch for:
   - No Instagram "action blocked" warnings
   - Bot stops after hitting limits
   - Creates daily_stats.json and followed.csv

---

## STEP 6: Set Up Cron Job for Daily Automation

### Option A: Run Once Daily (Recommended)

```bash
# Edit crontab
crontab -e

# Add this line (runs at 10:00 AM UTC daily)
0 10 * * * /root/ig-engagement-bot/run_bot_automated.sh

# Save and exit (Ctrl+X, then Y, then Enter)
```

### Option B: Run Twice Daily (More Aggressive)

```bash
# Runs at 10 AM and 6 PM UTC daily
0 10,18 * * * /root/ig-engagement-bot/run_bot_automated.sh
```

### Option C: Run Every 12 Hours

```bash
# Runs every 12 hours
0 */12 * * * /root/ig-engagement-bot/run_bot_automated.sh
```

---

## STEP 7: Verify Cron Job is Active

```bash
# List your cron jobs
crontab -l

# Check if cron service is running
systemctl status cron
```

---

## STEP 8: Add All 500 Profiles to targets.csv

Now that automation is set up, add all 500 usernames to `data/targets.csv`:

```csv
username
profile1
profile2
profile3
...
profile500
```

---

## STEP 9: Monitor Bot Remotely

### Check Logs
```bash
# View today's log
tail -f /root/ig-engagement-bot/logs/bot_$(date +%Y%m%d).log

# View last 50 lines
tail -50 /root/ig-engagement-bot/logs/bot_$(date +%Y%m%d).log

# Search for errors
grep -i "error\|blocked\|failed" /root/ig-engagement-bot/logs/bot_*.log
```

### Check Daily Stats
```bash
cat /root/ig-engagement-bot/data/daily_stats.json
```

### Check Progress (How Many Processed)
```bash
wc -l /root/ig-engagement-bot/data/followed.csv
```

---

## STEP 10: Create Monitoring Dashboard (Optional)

Create a simple status check script:

```bash
nano /root/ig-engagement-bot/check_status.sh
```

Paste this:
```bash
#!/bin/bash
echo "=== Instagram Bot Status ==="
echo ""
echo "Today's Date: $(date +%Y-%m-%d)"
echo ""
echo "Daily Stats:"
cat /root/ig-engagement-bot/data/daily_stats.json
echo ""
echo ""
echo "Total Profiles Processed:"
wc -l /root/ig-engagement-bot/data/followed.csv
echo ""
echo "Profiles Remaining:"
TOTAL=$(wc -l < /root/ig-engagement-bot/data/targets.csv)
DONE=$(wc -l < /root/ig-engagement-bot/data/followed.csv)
REMAINING=$((TOTAL - DONE))
echo "$REMAINING profiles left to process"
echo ""
echo "Last 10 Log Lines:"
tail -10 /root/ig-engagement-bot/logs/bot_$(date +%Y%m%d).log
```

Make it executable:
```bash
chmod +x /root/ig-engagement-bot/check_status.sh
```

Run anytime to check status:
```bash
./check_status.sh
```

---

## 🎯 TIMELINE FOR 500 PROFILES

With 40 follows/day limit:
- **Day 1-12**: ~40 profiles/day
- **Day 13**: Final 20 profiles
- **Day 8+**: DMs start going out (15/day to 7-day-old follows)

**Total Duration**: ~13 days to process all 500

---

## ⚠️ IMPORTANT REMINDERS

### 1. Account Safety
- Bot runs once/twice daily automatically
- Stops at daily limits (40 follows, 35 comments, 15 DMs)
- Logs everything for monitoring

### 2. If Instagram Blocks You
```bash
# Stop the cron job immediately
crontab -e
# Comment out the line with #
# 0 10 * * * /root/ig-engagement-bot/run_bot_automated.sh

# Wait 24-48 hours
# Lower your limits in follow_comment_bot.js:
const DAILY_LIMITS = {
  follows: 25,     // Reduced from 40
  comments: 20,    // Reduced from 35
  dms: 10,         // Reduced from 15
  maxSessionHours: 3
};

# Re-enable cron after waiting period
```

### 3. IP Safety (CRITICAL!)
Digital Ocean IPs are risky. Consider:
- Using residential proxy service (Bright Data, Smartproxy)
- Routing through home internet via VPN
- Using mobile proxy rotation

---

## 📊 WHAT HAPPENS AUTOMATICALLY

**Every day at 10 AM (or your chosen time):**

1. ✅ Bot wakes up
2. ✅ Checks daily_stats.json (resets if new day)
3. ✅ Processes ~40 new profiles from targets.csv
4. ✅ Follows + Comments (with limits)
5. ✅ Checks followed.csv for 7-day-old profiles
6. ✅ Sends DMs to qualified profiles (max 15)
7. ✅ Updates all CSV files
8. ✅ Logs everything
9. ✅ Stops automatically when limits hit
10. ✅ Waits until next day

**You don't need to do anything!**

---

## 🔧 TROUBLESHOOTING

### Bot Not Running?
```bash
# Check cron logs
grep CRON /var/log/syslog

# Test automation script manually
/root/ig-engagement-bot/run_bot_automated.sh
```

### Session Expired?
```bash
# Re-login manually
cd /root/ig-engagement-bot
node main_login.js

# Then let automation continue
```

### Need to Pause Automation?
```bash
# Disable cron temporarily
crontab -e
# Add # at start of line to comment it out
```

---

## 🎉 YOU'RE DONE!

The bot will now run automatically every day, process 40 profiles, send DMs to 7-day-old follows, and stop at safe limits.

**Check progress weekly:**
```bash
ssh root@your-droplet-ip
cd /root/ig-engagement-bot
./check_status.sh
```