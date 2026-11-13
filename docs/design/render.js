// Rende le schermate di prova di docs/design/mockup.html in PNG.
// Uso: node docs/design/render.js   (serve Playwright con Chromium)
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  const file = 'file://' + path.resolve(__dirname, 'mockup.html');
  for (const s of ['home', 'cane', 'allarme']) {
    for (const t of ['chiaro', 'scuro']) {
      await p.goto(`${file}?s=${s}&t=${t}`);
      await p.evaluate(() => document.fonts.ready);
      await p.screenshot({ path: path.join(__dirname, `${s}-${t}.png`) });
    }
  }
  await b.close();
})();
