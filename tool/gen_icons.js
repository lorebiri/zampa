// Genera le icone di Lulù (web e Android) da una zampa in pixel art.
// Uso: node tool/gen_icons.js .   (serve Playwright con Chromium)
const { chromium } = require('playwright');
const fs = require('fs');
// Zampa in pixel art (griglia 16x16): cuscinetto e quattro dita.
const paw = [
  '................',
  '.....##..##.....',
  '....###..###....',
  '.##.###..###.##.',
  '.##..#....#..##.',
  '.##..........##.',
  '................',
  '......####......',
  '.....######.....',
  '....########....',
  '...##########...',
  '...##########...',
  '....###..###....',
  '................',
  '................',
  '................',
];
function svg(size, {pad, radius, bg='#22406A', fg='#F2B53A'}) {
  const inner = size * (1 - 2*pad), cell = inner/16, off = size*pad;
  let r = '';
  paw.forEach((row,y)=>[...row].forEach((c,x)=>{ if(c==='#') r+=`<rect x="${off+x*cell}" y="${off+(y+1)*cell}" width="${cell+0.5}" height="${cell+0.5}" fill="${fg}"/>`; }));
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" shape-rendering="crispEdges"><rect width="${size}" height="${size}" rx="${size*radius}" fill="${bg}"/>${r}</svg>`;
}
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({deviceScaleFactor:1});
  const out = process.argv[2];
  const jobs = [
    ['web/icons/Icon-192.png',192,{pad:0.12,radius:0}],
    ['web/icons/Icon-512.png',512,{pad:0.12,radius:0}],
    ['web/icons/Icon-maskable-192.png',192,{pad:0.2,radius:0}],
    ['web/icons/Icon-maskable-512.png',512,{pad:0.2,radius:0}],
    ['web/icons/apple-touch-icon.png',180,{pad:0.14,radius:0}],
    ['web/favicon.png',32,{pad:0.02,radius:0.2}],
    ['android/app/src/main/res/mipmap-mdpi/ic_launcher.png',48,{pad:0.12,radius:0.22}],
    ['android/app/src/main/res/mipmap-hdpi/ic_launcher.png',72,{pad:0.12,radius:0.22}],
    ['android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',96,{pad:0.12,radius:0.22}],
    ['android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',144,{pad:0.12,radius:0.22}],
    ['android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',192,{pad:0.12,radius:0.22}],
    ['web/icons/Icon-source.svg',512,{pad:0.12,radius:0},true],
  ];
  for (const [f,s,o,raw] of jobs) {
    const s1 = svg(s,o);
    if (raw) { fs.writeFileSync(`${out}/${f}`, s1); continue; }
    await p.setViewportSize({width:s,height:s});
    await p.setContent(`<html><body style="margin:0;background:transparent">${s1}</body></html>`);
    await p.locator('svg').screenshot({path:`${out}/${f}`, omitBackground:true});
  }
  await b.close();
})();
