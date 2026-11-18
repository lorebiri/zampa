const { chromium, devices } = require('playwright');
const OUT = '/home/user/zampa/docs/design/';
const URL = 'http://localhost:8765/zampa/';
const wait = (p, ms) => p.waitForTimeout(ms);
async function semantics(page) {
  await page.waitForSelector('flt-semantics-placeholder, flt-glass-pane, flutter-view', { timeout: 60000 });
  await wait(page, 2500);
  await page.evaluate(() => {
    const b = document.querySelector('flt-semantics-placeholder');
    if (b) b.click();
  });
  await wait(page, 800);
}
const L = (page, re) => page.getByText(re).or(page.getByLabel(re)).or(page.getByRole('button', { name: re })).or(page.getByRole('tab', { name: re }));
async function tapText(page, re, opts = {}) {
  const loc = L(page, re).first();
  await loc.waitFor({ timeout: 20000 });
  await loc.scrollIntoViewIfNeeded().catch(() => {});
  await loc.click(opts);
  await wait(page, 900);
}
async function tapRole(page, role, re) {
  const loc = page.getByRole(role, { name: re }).first();
  await loc.waitFor({ timeout: 20000 });
  await loc.scrollIntoViewIfNeeded().catch(() => {});
  await loc.click();
  await wait(page, 900);
}
async function scrollToText(page, re) {
  const vh = page.viewportSize().height;
  for (let i = 0; i < 40; i++) {
    const loc = L(page, re).first();
    if (await L(page, re).count()) {
      const b = await loc.boundingBox().catch(() => null);
      if (b && b.y > 40 && b.y + b.height < vh - 110) { await wait(page, 400); return true; }
      const dy = b ? Math.max(-400, Math.min(400, b.y - vh / 2)) : 300;
      await page.mouse.move(200, vh / 2);
      await page.mouse.wheel(0, dy);
    } else {
      await page.mouse.move(200, vh / 2);
      await page.mouse.wheel(0, 300);
    }
    await wait(page, 350);
  }
  return false;
}
(async () => {
  const which = process.argv[2] || 'desktop';
  const scheme = process.argv[3] || 'light';
  const browser = await chromium.launch();
  const ctxOpts = which === 'iphone'
    ? { ...devices['iPhone 13'], colorScheme: scheme }
    : { viewport: { width: 1280, height: 900 }, deviceScaleFactor: 2, colorScheme: scheme };
  const ctx = await browser.newContext(ctxOpts);
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(URL, { waitUntil: 'load' });
  await semantics(page);
  const tag = `unione-${which}-${scheme === 'dark' ? 'scuro' : 'chiaro'}`;
  await scrollToText(page, /Ho letto e ho capito/);
  await tapText(page, /Ho letto e ho capito/);
  await scrollToText(page, /^Continua$/);
  await tapText(page, /^Continua$/);
  await scrollToText(page, /cane di esempio/);
  await tapText(page, /cane di esempio/);
  await wait(page, 2500);
  // Chiude eventuali avvisi (dispositivo web).
  for (const t of [/^Ho capito$/, /^OK$/, /^Chiudi$/]) {
    if (await L(page, t).count()) await tapText(page, t).catch(()=>{});
  }
  await page.screenshot({ path: OUT + `${tag}-oggi.png` });
  await tapRole(page, 'tab', /Bisogni/).catch(async () => tapText(page, /^Bisogni$/));
  await wait(page, 1500);
  await page.screenshot({ path: OUT + `${tag}-bisogni.png` });
  const ok = await scrollToText(page, /Va alla porta/);
  console.log('chip trovato', ok);
  await page.screenshot({ path: OUT + `${tag}-segnali.png` });
  await scrollToText(page, /Va alla porta/);
  await tapText(page, /Va alla porta/);
  await wait(page, 1200);
  // Torna su per vedere l'avviso.
  const vh0 = page.viewportSize().height;
  await page.mouse.move(200, vh0 / 2);
  for (let i = 0; i < 30; i++) { await page.mouse.wheel(0, -600); await wait(page, 120); }
  await wait(page, 800);
  await scrollToText(page, /Esci adesso con/);
  await wait(page, 600);
  const banner = await L(page, /Esci adesso con/).count();
  console.log('avviso Esci adesso', banner);
  await page.screenshot({ path: OUT + `${tag}-esci-adesso.png` });
  // Piano di uscite.
  if (await scrollToText(page, /Quante uscite vuoi fare/)) await page.screenshot({ path: OUT + `${tag}-piano.png` });
  // Cacca.
  for (let i = 0; i < 20; i++) { await page.mouse.wheel(0, -500); await wait(page, 120); }
  await tapText(page, /^Cacca$/).catch(()=>{});
  await wait(page, 1000);
  await page.screenshot({ path: OUT + `${tag}-cacca.png` });
  // Oggi: il compagno impaziente alla porta.
  await tapRole(page, 'tab', /Oggi/).catch(async () => tapText(page, /^Oggi$/));
  await wait(page, 1500);
  const mood = await L(page, /impaziente alla porta/).count();
  console.log('compagno impaziente', mood);
  await page.screenshot({ path: OUT + `${tag}-compagno.png` });
  console.log('errori', JSON.stringify(errors.slice(0, 5)));
  await browser.close();
  process.exit(banner && mood ? 0 : 3);
})().catch(e => { console.error(e); process.exit(1); });
