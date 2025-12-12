const { chromium } = require('playwright');
const fs = require('fs');

const SESSION_PATH = './data/session.json';
const TARGETS_PATH = './data/targets.csv';
const FOLLOWED_PATH = './data/followed.csv';

// --- Helpers for delays, scrolls, and human typing ---
function sleep(ms) { return new Promise(res => setTimeout(res, ms)); }
function randomDelay(min, max) { return min + Math.floor(Math.random() * (max - min)); }

const COMMENTS = [
  "🔥 Great content!",
  "Love your posts! 🙌",
  "Awesome work 👏",
  "Keep it up! 💯",
  "Really inspiring! 😊"
];

function readTargets() {
  if (!fs.existsSync(TARGETS_PATH)) throw new Error('targets.csv not found!');
  const data = fs.readFileSync(TARGETS_PATH, 'utf-8')
    .split('\n').map(line => line.trim()).filter(Boolean);
  return data[0].toLowerCase() === 'username' ? data.slice(1) : data;
}

function readAlreadyFollowed() {
  if (!fs.existsSync(FOLLOWED_PATH)) return [];
  return fs.readFileSync(FOLLOWED_PATH, 'utf-8')
    .split('\n').map(line => line.split(',')[0]).filter(Boolean);
}

function logFollowed(username) {
  fs.appendFileSync(FOLLOWED_PATH, `${username},${Date.now()}\n`);
}

function randomComment() {
  return COMMENTS[Math.floor(Math.random() * COMMENTS.length)];
}

async function slowScroll(page, steps = 3, delay = 1200) {
  for (let i = 0; i < steps; i++) {
    await page.mouse.wheel(0, 250 + Math.random() * 120);
    await sleep(delay + randomDelay(600, 1600));
  }
}

// -------------------------------------------------
// MAIN BOT
// -------------------------------------------------
(async () => {
  if (!fs.existsSync(SESSION_PATH)) throw new Error('session.json not found! Login first.');

  const browser = await chromium.launch({
    headless: false,
    args: ['--window-size=1920,864', '--force-device-scale-factor=1']
  });
  const context = await browser.newContext({ storageState: SESSION_PATH, viewport: { width: 1200, height: 800 } });
  const page = await context.newPage();

  const targets = readTargets();
  const alreadyFollowed = readAlreadyFollowed();

  let userCount = 0;
  for (const username of targets) {
    if (!username || alreadyFollowed.includes(username)) continue;
    console.log(`\n=== Processing @${username} ===`);

    try {
      // 1. Open profile
      await page.goto(`https://www.instagram.com/${username}/`, { waitUntil: 'domcontentloaded' });
      await sleep(randomDelay(6500, 10500));
      await sleep(randomDelay(4500, 7500));

      // 2. Follow
      let followBtn = await page.$('button:has-text("Follow")');
      if (!followBtn) followBtn = await page.$('button._aswp._aswr._aswu._asw_._asx2');
      if (followBtn) {
        await followBtn.hover();
        await sleep(randomDelay(2000, 4000));
        await followBtn.click();
        console.log(`✅ Followed ${username}`);
        logFollowed(username);
        await sleep(randomDelay(4200, 6500));
      } else {
        console.log(`⚠️ Already following or button not found for ${username}`);
      }

      await sleep(randomDelay(4000, 7000));

      // 3. Scroll & open latest post
      let postFound = false;
      for (let scroll = 0; scroll < 4; scroll++) {
        const latestPost = await page.$('div._aagw');
        if (latestPost) {
          await latestPost.scrollIntoViewIfNeeded();
          await sleep(randomDelay(1500, 3500));
          await latestPost.hover();
          await sleep(randomDelay(1200, 2500));
          await latestPost.click();
          postFound = true;
          break;
        }
        await slowScroll(page, 1, randomDelay(1500, 2200));
      }
      if (!postFound) {
        console.log(`⚠️ No posts found for ${username}`);
        continue;
      }

      await sleep(randomDelay(4800, 9500));

      // 4. Type comment – FIXED: fresh handle every character
      const finalText = randomComment();
      for (const ch of finalText) {
        const freshBox = await page.waitForSelector(
          'textarea[aria-label="Add a comment…"]', { timeout: 5000 }
        );
        await freshBox.type(ch, { delay: randomDelay(80, 170) });
        await sleep(randomDelay(60, 190));
      }
      await sleep(randomDelay(2300, 4000));

      // 5. Post button
      let postBtn = await page.$('div[role="button"][tabindex="0"]:has-text("Post")');
      if (!postBtn) {
        const span = await page.$('span.x1loumh:has-text("Post")');
        if (span) postBtn = await span.evaluateHandle(node => node.closest('div[role="button"]'));
      }
      if (!postBtn) {
        postBtn = await page.$('div.x1i10hfl.xjqpnuy.xc5r6h4.xqeqjp1.x1phubyo.xdl72j9.x2lah0s.x3ct3a4.xdj266r.x14z9mp.xat24cr.x1lziwak.x2lwn1j.xeuugli.x1hl2dhg.xggy1nq.x1ja2u2z.x1t137rt.x1q0g3np.x1a2a7pz.x6s0dn4.xjyslct.x1ejq31n.x18oe1m7.x1sy0etr.xstzfhl.x9f619.x1ypdohk.x1f6kntn.xl56j7k.x17ydfre.x2b8uid.xlyipyv.x87ps6o.x14atkfc.x5c86q.x18br7mf.x1i0vuye.xr5sc7.xlal1re.x14jxsvd.xt0b8zv.xjbqb8w.xr9e8f9.x1e4oeot.x1ui04y5.x6en5u8.x972fbf.x10w94by.x1qhh985.x14e42zd.xt0psk2.xt7dq6l.xexx8yu.xyri2b.x18d9i69.x1c1uobl.x1n2onr6.x1n5bzlp');
      }
      if (postBtn) {
        await postBtn.hover();
        await sleep(randomDelay(1100, 2200));
        await postBtn.click();
        console.log(`💬 Commented on @${username}`);
      } else {
        console.log(`❗Post button not found for ${username}`);
      }

      await sleep(randomDelay(2300, 3700));

      // 6. Close popup
      const closeBtn = await page.$('svg[aria-label="Close"]');
      if (closeBtn) await closeBtn.click();

      // 7. Idle delay
      const idleDelay = randomDelay(40000, 90000);
      console.log(`⏸️  Waiting ${Math.floor(idleDelay / 1000)} seconds to mimic human...`);
      await sleep(idleDelay);

      // 8. Coffee break
      userCount++;
      if (userCount % randomDelay(8, 12) === 0) {
        const longBreak = randomDelay(240000, 420000);
        console.log(`☕ Coffee break! Pausing for ${Math.floor(longBreak / 1000 / 60)} min...`);
        await sleep(longBreak);
      }

    } catch (e) {
      console.log(`❌ Error with @${username}: ${e.message}`);
      try {
        const closeBtn = await page.$('svg[aria-label="Close"]');
        if (closeBtn) await closeBtn.click();
      } catch {}
    }
  }

    // ===== 7-DAY DM SCHEDULER (inline) =====
  console.log('\n[INFO] Checking for 7-day DM candidates...');

  const now = Date.now();
  const WEEK = 7 * 24 * 60 * 60 * 1000;

  // read FOLLOWED_PATH  (== ./data/followed.csv)
  const followedRows = fs.readFileSync(FOLLOWED_PATH, 'utf-8')
    .split('\n')
    .map(l => l.trim())
    .filter(Boolean)
    .map(l => {
      const [user, ts, dmFlag] = l.split(',');
      return { user, ts: Number(ts || 0), dmSent: dmFlag === 'true' };
    });

  const dmTargets = followedRows.filter(r => !r.dmSent && (now - r.ts >= WEEK));

  if (dmTargets.length === 0) {
    console.log('[INFO] No 7-day DMs due yet.');
  } else {
    console.log(`[INFO] ${dmTargets.length} account(s) ready for DM: ${dmTargets.map(t => t.user).join(', ')}`);
  }

  /* send DMs */
  for (const t of dmTargets) {
    const username = t.user;
    console.log(`\n[DM] → @${username}`);

    try {
      await page.goto('https://www.instagram.com/direct/new/', { waitUntil: 'domcontentloaded' });
      await sleep(randomDelay(3500, 5500));

      const searchBox = await page.waitForSelector('input[placeholder="Search..."]', { timeout: 10000 });
      await searchBox.type(username, { delay: randomDelay(120, 220) });
      await sleep(randomDelay(2500, 4000));

      const userResult = await page.waitForSelector(`div[role="button"]:has-text("${username}")`, { timeout: 10000 });
      await userResult.click();
      await sleep(randomDelay(1500, 3000));

      const nextBtn = await page.waitForSelector('div[role="button"]:has-text("Next"), button:has-text("Chat")', { timeout: 8000 });
      await nextBtn.click();
      await sleep(randomDelay(3500, 5500));

      try { await page.click('button:has-text("Not Now")', { timeout: 3500 }); } catch {}

      const msgText = `Hey ${username}, just checking in – hope you’re doing great 😊`;
      for (const ch of msgText) {
        const freshBox = await page.waitForSelector('div[contenteditable="true"][data-lexical-editor="true"]', { timeout: 10000 });
        await freshBox.type(ch, { delay: randomDelay(80, 170) });
        await sleep(randomDelay(60, 190));
      }
      await sleep(randomDelay(1500, 3000));
      await page.keyboard.press('Enter');
      console.log(`[SUCCESS] DM sent to @${username}`);

      // mark as dm_sent
      const oldContent = fs.readFileSync(FOLLOWED_PATH, 'utf-8');
      fs.writeFileSync(
        FOLLOWED_PATH,
        oldContent.replace(
          `${username},${t.ts}${t.dmSent ? ',true' : ''}`,
          `${username},${t.ts},true`
        )
      );

      await sleep(randomDelay(45000, 90000));
    } catch (e) {
      console.log(`[ERROR] DM failed for @${username}: ${e.message}`);
      await page.screenshot({ path: `errorScreenshots/dm7_${username}_error.png`, fullPage: true });
    }
  }
  // ===== END 7-DAY DM SCHEDULER =====

  await browser.close();
  console.log("\n✅ All done (ultra-safe and robust)!");
})();