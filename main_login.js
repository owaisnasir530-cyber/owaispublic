const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto('https://www.instagram.com/accounts/login/');

  console.log('\nPlease log in to Instagram in the browser window.');
  console.log('Once you see your home feed, come back here and press Enter to save the session.\n');

  process.stdin.resume();
  process.stdin.on('data', async () => {
    const sessionFile = './data/session.json'; // Save in your data folder!
    if (fs.existsSync(sessionFile)) {
      fs.unlinkSync(sessionFile);
      console.log(`[INFO] Existing session file deleted.`);
    }
    await context.storageState({ path: sessionFile });
    await browser.close();
    console.log(`✅ IG session saved as ${sessionFile}`);
    process.exit(0);
  });
})();
