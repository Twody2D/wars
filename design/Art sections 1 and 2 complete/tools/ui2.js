V.F['%'] = '##..#|##..#|...#.|..#..|.#...|#..##|#..##'.split('|');
V.F['×'] = '.....|#...#|.#.#.|..#..|.#.#.|#...#|.....'.split('|');
V.F[':'] = '.....|..#..|..#..|.....|..#..|..#..|.....'.split('|');
V.lighten = (hex, t) => { const n = parseInt(hex.slice(1), 16); return '#' + [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(v => Math.round(v + (255 - v) * t).toString(16).padStart(2, '0')).join('').toUpperCase(); };
V.mix = (a, b, t) => { const p = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)); const A = p(a), B = p(b); return '#' + A.map((v, i) => Math.round(v + (B[i] - v) * t).toString(16).padStart(2, '0')).join('').toUpperCase(); };
V.dim = (svg, t = 0.6, to = '#2B2740') => svg.replace(/#[0-9A-Fa-f]{6}/g, h => V.mix(h.toUpperCase(), to, t));
V.rr = (x, y, w, h, r, f, st = true) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${f}"${st ? ` stroke="${V.OL}" stroke-width="3"` : ''}/>`;
V.BC = { primary: {f: V.C.grass, e: V.C.grassD, h: V.C.grassL}, secondary: {f: V.C.blue, e: V.shade(V.C.blue, 0.72), h: V.C.sky},
  danger: {f: V.C.red, e: V.shade(V.C.red, 0.72), h: V.C.pink}, gold: {f: V.C.yel, e: V.C.yelD, h: V.C.white}, orange: {f: V.C.org, e: V.C.orgD, h: V.C.yel},
  disabled: {f: V.C.greyL, e: V.C.grey, h: null} };
V.btn2 = (x, y, w, h, c, state = 'normal', r = 12) => {
  if (state === 'disabled') c = V.BC.disabled;
  if (state === 'pressed') return V.rr(x + 1.5, y + 7.5, w - 3, h - 9, r, c.f);
  const face = state === 'hover' ? V.lighten(c.f, 0.12) : c.f;
  let s = V.rr(x + 1.5, y + 1.5, w - 3, h - 3, r, c.e) + V.rr(x + 3, y + 3, w - 6, h - 14, r - 2, face, false);
  if (state === 'hover') s += `<rect x="${x + 14}" y="${y + 8}" width="${w - 28}" height="4" fill="#FFFFFF"/>`;
  else if (state === 'normal' && c.h) { const hw = Math.min(36, Math.round(w * 0.16)); s += `<path d="M${x + 11} ${y + 10}h${hw}v5h${-hw + 5}v5h-5z" fill="${c.h}"/>`; }
  return s; };
V.tab = (x, y, state) => { const C = V.C;
  if (state === 'active') return V.rr(x + 1.5, y + 1.5, 277, 100, 12, C.yelD) + V.rr(x + 3, y + 3, 274, 77, 10, C.yel, false) + `<path d="M${x + 12} ${y + 10}h36v5h-31v5h-5z" fill="${C.white}"/>`;
  return V.rr(x + 1.5, y + 9.5, 277, 100, 12, C.caveD) + V.rr(x + 3, y + 11, 274, 69, 10, state === 'hover' ? C.caveL : C.cave, false); };
V.ctext = (s, cx, y, px, f) => V.text(s, Math.round(cx - V.textW(s, px) / 2), y, px, f);
V.lab = (s, cx, cy, px, o = {}) => { const d = o.depth ?? 4; return V.btext(s, Math.round(cx - V.textW(s, px) / 2 - d / 2), Math.round(cy - 3.5 * px - d / 2), px, {face: o.face ?? '#FFFFFF', side: o.side ?? V.OL, depth: d}); };
V.pip = (x, y, full) => V.r(x + 1.5, y + 1.5, 17, 17, full ? V.C.yel : V.C.caveD) + (full ? `<path d="M${x + 5} ${y + 5}h4v4h-4z" fill="#FFFFFF"/>` : '');
V.pips = (x, y, n, gap = 6) => { let s = ''; for (let k = 0; k < 5; k++) s += V.pip(x + k * (20 + gap), y, k < n); return s; };
V.stamp = (grid, bm, ox, oy) => { const H = grid.length, W = grid[0].length, on = (r, c) => bm[r] && bm[r][c] && bm[r][c] !== '.';
  for (let r = -1; r <= bm.length; r++) for (let c = -1; c <= Math.max(...bm.map(x => x.length)); c++) { if (on(r, c)) continue;
    let adj = false; for (let dr = -1; dr <= 1; dr++) for (let dc = -1; dc <= 1; dc++) if (on(r + dr, c + dc)) adj = true;
    const R = oy + r, Cc = ox + c; if (adj && R >= 0 && R < H && Cc >= 0 && Cc < W && grid[R][Cc] !== '.') grid[R][Cc] = 'k'; }
  bm.forEach((row, r) => [...row].forEach((ch, c) => { if (ch !== '.') { const R = oy + r, Cc = ox + c; if (R >= 0 && R < H && Cc >= 0 && Cc < W) grid[R][Cc] = ch; } })); return grid; };
V.compose = (w, h, stamps) => { const g = Array.from({length: h}, () => Array(w).fill('.')); stamps.forEach(([bm, x, y]) => V.stamp(g, bm, x, y)); return g.map(r => r.join('')); };
V.BMP = {
  SWORD: ['.........lll', '........lwwl', '.......lwwl.', '......lwwl..', '.....lwwl...', '..y.lwwl....', '..yylwl.....', '...yyl......', '..dDyyy.....', '.dDd..y.....', 'dDd.........', 'Dd..........'],
  ARROW: ['...e...', '..eee..', '.eeeee.', 'eeeeeee', '..eeE..', '..eeE..', '..eeE..'],
  FOOD: ['...oooooo...', '..oyyooooo..', '.oyoooooooO.', '.oooooooooO.', '.ooooooooOO.', '.ooooooooOO.', '..ooooooOO..', '...OOOOOO...', '.....bn.....', '.....bn.....', '...bbbnnn...', '...bn..bn...'],
  CLOCK: ['.kkkkk.', 'kwwkwwk', 'kwwkwwk', 'kwwkkkk', 'kwwwwwk', 'kwwwwwk', '.kkkkk.'],
  HUT: ['....eeee....', '..eeeeeeee..', 'eeeeeeeeeeee', 'EEEEEEEEEEEE', '.dddddddddd.', '.dssdddDCCd.', '.dssdddDCCd.', '.ddddddDCCd.', '.gggggggggg.'],
  HEART: ['.RR.RR.', 'RwRRRRR', 'RRRRRRR', '.RRRRR.', '..RRR..', '...R...'],
  FLAG: ['Duuuuu.', 'Duuuuuu', 'Duuuuu.', 'D......', 'D......', 'D......', 'D......'],
  STAR: ['.....yY.....', '....yyyY....', '....ywyY....', 'yyyyywyyyyYY', '.yyyywyyyyY.', '..yyyyyyyY..', '...yyyyyY...', '..yyyyyyyY..', '..yyyY.yyyY.', '.yyY....yyY.', '.yY......YY.'],
  HOUR: ['DDDDDDDDDD', '.lwwwwwwl.', '.lyyyyyyl.', '..lyyyyl..', '...lyyl...', '....ll....', '...lwyl...', '..lwwyyl..', '.lwyyyyyl.', '.lyyyyyyl.', 'DDDDDDDDDD'],
  AD: ['...k....k...', '....k..k....', 'gggggggggggG', 'gCCCCCCCCCgG', 'gCCCwCCCCCgG', 'gCCCwwCCCCgG', 'gCCCwwwCCCgG', 'gCCCwwCCCCgG', 'gCCCwCCCCCgG', 'gCCCCCCCCCgG', 'GGGGGGGGGGGG'],
  METEOR: ['.........yo', '.......yoo.', '.....yoo...', '..GGGGo....', '.GgggggG...', '.GgOgggG...', '.GgggOgG...', '.GgggggG...', '..GGGGG....'],
  WFLAG: ['D.......', 'Dwwwwww.', 'Dwwwwwww', 'Dwwwwww.', 'Dnnnnn..', 'D.......', 'D.......', 'D.......'],
  CHEV: ['ww..ww..', '.ww..ww.', '..ww..ww', '.ww..ww.', 'ww..ww..'],
  PLUS: ['..ee..', '..ee..', 'eeeeee', 'eeeeee', '..ee..', '..ee..']
};
