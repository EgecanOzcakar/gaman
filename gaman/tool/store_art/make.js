// Store screenshots (framed, captioned) and the Play feature graphic, made
// from the real web build with seeded sample data, with no design tool.
//
//   flutter build web --release
//   (cd build/web && python3 -m http.server 8080) &
//   node tool/store_art/make.js            # from the app root (gaman/)
//
// Writes store/screenshots/*.png at 1290x2796 (App Store 6.7"/6.9"; also
// valid for Play phone) and store/feature-graphic.png at 1024x500.
// Re-run whenever the UI changes. Needs Playwright with Chromium.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const OUT = path.join(ROOT, 'store');
const FONTS = path.join(ROOT, 'assets/google_fonts');
const URL = process.env.APP_URL || 'http://localhost:8080/';
const W = 1290, H = 2796;

const CAPTIONS = [
  ['endure', 'When the urge hits,\nride it out for ten minutes.'],
  ['today', 'A daily Stoic loop.\nOne hard thing on purpose.'],
  ['insights', 'Miss a day? Mended in gold.\nJust never miss twice.'],
  ['trials', 'Trials from gentle to hard,\nchosen by you.'],
  ['programs', 'Go further with programs\nof 14 to 30 days.'],
];

function seed() {
  const now = Date.now(), day = 864e5, ev = [];
  const tags = ['Phone', 'Food', 'Phone', 'Anger', 'Smoking'];
  for (const d of [20, 19, 18, 17, 16, 15, 13, 12, 11, 10, 9, 8, 6, 5, 4, 3, 2, 1]) {
    const at = new Date(now - d * day).toISOString();
    ev.push(JSON.stringify({ type: 'journal', at, dur: 0, meta: { template: 'evening' } }));
    ev.push(JSON.stringify({ type: 'urge', at, dur: 600, meta: { tag: tags[d % 5], held: d % 4 !== 0 } }));
    if (d % 2) ev.push(JSON.stringify({ type: 'trial', at, dur: 0, meta: { id: 'stairs', status: 'done' } }));
  }
  // Today: an evening's worth of practice, so "this week" isn't empty.
  const today = (h) => { const t = new Date(); t.setHours(h, 0, 0, 0); return t.toISOString(); };
  ev.push(JSON.stringify({ type: 'journal', at: today(7), dur: 0, meta: { template: 'premeditatio' } }));
  ev.push(JSON.stringify({ type: 'trial', at: today(7), dur: 0, meta: { id: 'cold_finish', status: 'chosen' } }));
  ev.push(JSON.stringify({ type: 'urge', at: today(9), dur: 600, meta: { tag: 'Phone', held: true } }));
  ev.push(JSON.stringify({ type: 'urge', at: today(10), dur: 600, meta: { tag: 'Food', held: true } }));
  ev.push(JSON.stringify({ type: 'focus', at: today(11), dur: 1500 }));
  return ev;
}

async function captureApp(browser) {
  // 430x932 CSS px at 3x = 1290x2796.
  const ctx = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
  await ctx.addInitScript((list) => {
    if (sessionStorage.getItem('seeded')) return;
    sessionStorage.setItem('seeded', '1');
    localStorage.setItem('flutter.onboarding_done', 'true');
    localStorage.setItem('flutter.activity_log', JSON.stringify(list));
  }, seed());
  const p = await ctx.newPage();
  await p.goto(URL, { waitUntil: 'load' });
  await p.waitForTimeout(9000);
  await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await p.waitForTimeout(1000);
  const shots = {};
  const snap = async (k) => { await p.waitForTimeout(1500); shots[k] = await p.screenshot(); };
  // tap(), not click(): a mouse hover would leave the tab tooltip in the shot.
  const tab = (name) => p.getByRole('tab', { name }).tap();
  await snap('today');
  await tab('Insights'); await snap('insights');
  await tab('Endure'); await snap('endure');
  await p.getByRole('button', { name: /Change/ }).first().tap(); await snap('trials');
  await p.keyboard.press('Escape'); await p.waitForTimeout(800);
  await p.mouse.move(215, 600); await p.mouse.wheel(0, 520); await snap('programs');
  await ctx.close();
  return shots;
}

const fontFace = `
  @font-face { font-family: Garamond; src: url(file://${FONTS}/EBGaramond-Medium.ttf); }
  @font-face { font-family: Manrope; src: url(file://${FONTS}/Manrope-Medium.ttf); }`;

// Same algorithm as lib/widgets/enso.dart, so the store art matches the app.
const ensoJs = `
function enso(canvas, color) {
  const g = canvas.getContext('2d'), s = canvas.width, c = s / 2;
  const maxW = s * 0.11, r = s / 2 - maxW / 2, N = 240;
  g.fillStyle = color;
  for (let i = 0; i <= N; i++) {
    const t = i / N;
    const w = maxW * (0.35 + 0.65 * Math.pow(1 - t, 0.6)) * (0.85 + 0.15 * Math.sin(t * Math.PI * 3));
    const a = Math.PI * 0.62 + Math.PI * 1.82 * t;
    const rr = r * (1 + 0.025 * Math.sin(t * Math.PI * 5));
    g.beginPath(); g.arc(c + Math.cos(a) * rr, c + Math.sin(a) * rr, w / 2, 0, 2 * Math.PI); g.fill();
  }
}`;

async function frame(browser, png, caption) {
  const p = await browser.newPage({ viewport: { width: W, height: H } });
  const img = `data:image/png;base64,${png.toString('base64')}`;
  await p.setContent(`<html><head><style>${fontFace}
    body { margin:0; width:${W}px; height:${H}px; background:#ECEDE8; overflow:hidden; }
    h1 { font: 500 92px/1.15 Garamond; color:#1C2B2B; margin:150px 110px 0; white-space:pre-line; }
    .phone { position:absolute; left:50%; top:560px; transform:translateX(-50%);
      width:${Math.round(W * 0.8)}px; border-radius:64px; overflow:hidden;
      box-shadow:0 0 0 2px #C9CFCB, 0 40px 90px rgba(28,43,43,.18); }
    .phone img { display:block; width:100%; }
  </style></head><body><h1>${caption}</h1><div class="phone"><img src="${img}"></div></body></html>`);
  await p.waitForTimeout(400);
  const out = await p.screenshot();
  await p.close();
  return out;
}

async function featureGraphic(browser) {
  const p = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  await p.setContent(`<html><head><style>${fontFace}
    body { margin:0; width:1024px; height:500px; background:#5F8F8C; display:flex; align-items:center; gap:56px; padding-left:96px; box-sizing:border-box; }
    h1 { font: 500 112px/1 Garamond; color:#1C2B2B; margin:0; letter-spacing:6px; }
    p { font: 500 34px/1.3 Manrope; color:#1C2B2B; opacity:.85; margin:18px 0 0; }
  </style></head><body><canvas id="c" width="220" height="220"></canvas>
    <div><h1>Gaman</h1><p>Get better at hard things.</p></div>
    <script>${ensoJs}; enso(document.getElementById('c'), '#1C2B2B');</script></body></html>`);
  await p.waitForTimeout(400);
  const out = await p.screenshot();
  await p.close();
  return out;
}

(async () => {
  const browser = await chromium.launch();
  fs.mkdirSync(path.join(OUT, 'screenshots'), { recursive: true });
  const shots = await captureApp(browser);
  for (const [i, [key, caption]] of CAPTIONS.entries()) {
    const out = path.join(OUT, 'screenshots', `${i + 1}-${key}.png`);
    fs.writeFileSync(out, await frame(browser, shots[key], caption));
    console.log('wrote', path.relative(ROOT, out));
  }
  fs.writeFileSync(path.join(OUT, 'feature-graphic.png'), await featureGraphic(browser));
  console.log('wrote store/feature-graphic.png');
  await browser.close();
})();
