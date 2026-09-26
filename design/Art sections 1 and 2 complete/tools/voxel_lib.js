// Voxel-cartoon SVG generator library. Load: const V = new Function(src + ';return V;')();
const V = {};
V.OL = '#1B1B2F';
V.C = {
  outline:'#1B1B2F', white:'#FFFFFF', bone:'#F2EEDF', boneD:'#CFC6A8', greyL:'#A7ABBD', grey:'#7A7F96', greyD:'#4E5368',
  yel:'#FFD23F', yelD:'#E0A800', org:'#FF8A3D', orgD:'#CF5F1E', wood:'#A8703F', woodD:'#6E4526', pink:'#FF7AA8',
  blue:'#3A7BFF', red:'#FF4A4A',
  sky:'#9FDCFF', grassL:'#B4E86A', grass:'#6CCB4A', grassD:'#3F9A36', zomL:'#A6C29E', zom:'#7F9C80', zomD:'#56705A',
  caveD:'#2B2740', cave:'#474063', caveL:'#6D6592', slimeL:'#B98AF0', slime:'#8B5CD6', slimeD:'#5E3AA3', crys:'#7FE7FF', teal:'#2FB5A8', tealD:'#1D7E78'
};
V.PALETTE = [
  ['SHARED', ['outline','white','bone','boneD','greyL','grey','greyD','yel','yelD','org','orgD','wood','woodD','pink']],
  ['TEAM', ['blue','red']],
  ['MEADOW BIOME', ['sky','grassL','grass','grassD','zomL','zom','zomD']],
  ['CAVE BIOME', ['caveD','cave','caveL','slimeL','slime','slimeD','crys','teal','tealD']]
];
(() => { const C = V.C; V.M = {
  zom:{b:C.zom,d:C.zomD,h:C.zomL}, org:{b:C.org,d:C.orgD,h:C.yel}, bone:{b:C.bone,d:C.boneD,h:C.white},
  grass:{b:C.grass,d:C.grassD,h:C.grassL}, grey:{b:C.grey,d:C.greyD,h:C.greyL}, stoneD:{b:C.greyD,d:C.caveD,h:C.grey},
  wood:{b:C.wood,d:C.woodD,h:C.boneD}, yel:{b:C.yel,d:C.yelD,h:C.white}, slime:{b:C.slime,d:C.slimeD,h:C.slimeL},
  teal:{b:C.teal,d:C.tealD,h:C.crys}, cave:{b:C.cave,d:C.caveD,h:C.caveL}, crys:{b:C.crys,d:C.teal,h:C.white},
  sky:{b:C.sky,d:C.greyL,h:C.white}, orgD:{b:C.orgD,d:C.woodD,h:C.org}
}; })();
V.shade = (hex, f = 0.85) => { const n = parseInt(hex.slice(1), 16);
  return '#' + [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(v => Math.round(v * f).toString(16).padStart(2, '0')).join('').toUpperCase(); };
V.dk = m => ({ b: V.shade(m.b), d: V.shade(m.d), h: V.shade(m.h) });
V.rng = s => () => { s |= 0; s = s + 0x6D2B79F5 | 0; let t = Math.imul(s ^ s >>> 15, 1 | s); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
V.rot = (p, [a, cx, cy]) => { const r = a * Math.PI / 180, dx = p[0] - cx, dy = p[1] - cy; return [cx + dx * Math.cos(r) - dy * Math.sin(r), cy + dx * Math.sin(r) + dy * Math.cos(r)]; };
V.r = (x, y, w, h, f, st = true, extra = '') => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${f}"${st ? ` stroke="${V.OL}" stroke-width="3"` : ''}${extra}/>`;
V.notch = (x, y, w, h, s) => `M${x + s} ${y}H${x + w - s}V${y + s}H${x + w}V${y + h - s}H${x + w - s}V${y + h}H${x + s}V${y + h - s}H${x}V${y + s}H${x + s}Z`;

V.G = class {
  constructor(id, rot, pivot) { this.id = id; this.rot = rot || null; this.pivot = pivot || (rot ? [rot[1], rot[2]] : null); this.els = []; this.bb = [1e9, 1e9, -1e9, -1e9]; this.seed = id.length * 97 + 7; }
  ext(x, y, w, h, erot = this._er) { for (let p of [[x, y], [x + w, y], [x, y + h], [x + w, y + h]]) { if (erot) p = V.rot(p, erot); if (this.rot) p = V.rot(p, this.rot);
    this.bb[0] = Math.min(this.bb[0], p[0] - 1.5); this.bb[1] = Math.min(this.bb[1], p[1] - 1.5); this.bb[2] = Math.max(this.bb[2], p[0] + 1.5); this.bb[3] = Math.max(this.bb[3], p[1] + 1.5); } }
  rect(x, y, w, h, f, st = true, erot) { this.ext(x, y, w, h, erot); this.els.push(V.r(x, y, w, h, f, st, erot ? ` transform="rotate(${erot.join(' ')})"` : '')); return this; }
  raw(s, bb) { this.els.push(s); if (bb) this.ext(...bb); return this; }
  path(d, f, bb, st = true) { return this.raw(`<path d="${d}" fill="${f}"${st ? ` stroke="${V.OL}" stroke-width="3"` : ''}/>`, bb); }
  fill(d, f) { return this.raw(`<path d="${d}" fill="${f}"/>`); }
  blk(x, y, w, h, m, o = {}) {
    if (o.rot) { this._er = o.rot; this.els.push(`<g transform="rotate(${o.rot.join(' ')})">`); }
    this.rect(x, y, w, h, m.b);
    const i = 1.5, X2 = x + w - i, Y2 = y + h - i;
    const sd = o.sd ?? Math.max(3, Math.round(Math.min(w, h) * 0.18));
    const sides = o.sides ?? 'rb'; let d = '';
    if (sides === 'rb') d = `M${X2 - sd} ${y + i}H${X2}V${Y2}H${x + i}V${Y2 - sd}H${X2 - sd}Z`;
    else if (sides === 'b') d = `M${x + i} ${Y2 - sd}H${X2}V${Y2}H${x + i}Z`;
    else if (sides === 'r') d = `M${X2 - sd} ${y + i}H${X2}V${Y2}H${X2 - sd}Z`;
    if (d) this.els.push(`<path d="${d}" fill="${m.d}"/>`);
    if (w >= 14 && h >= 14 && o.hi !== false) { const hw = Math.max(5, Math.round((w - 2 * i) * 0.28)), hx = x + i + 3, hy = y + i + 3;
      this.els.push(`<path d="M${hx} ${hy}h${hw}v4h${-hw + 4}v4h-4z" fill="${m.h}"/>`); }
    const tex = o.tex ?? (w * h >= 2400 ? 3 : (w * h >= 1200 ? 1 : 0));
    if (tex) { const R = V.rng(this.seed += 13 + Math.round(x * 7 + y)); let p = '';
      const aw = Math.max(0, w - 2 * i - 18 - sd), ah = Math.max(0, h - 2 * i - 22 - sd);
      for (let k = 0; k < tex; k++) { const tx = Math.round(x + i + 10 + R() * aw), ty = Math.round(y + i + 12 + R() * ah); p += `M${tx} ${ty}h4v4h-4z`; }
      this.els.push(`<path d="${p}" fill="${o.texC ?? m.d}"/>`); }
    if (o.rot) { this.els.push('</g>'); this._er = null; }
    return this;
  }
  svg() { return `<g id="${this.id}"${this.rot ? ` transform="rotate(${this.rot.join(' ')})"` : ''}>${this.els.join('')}</g>`; }
};

V.svg = (w, h, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">\n${body}\n</svg>\n`;

// ---- 5x7 voxel block font (Latin caps, digits, Cyrillic subset) ----
V.F = {};
(() => { const src = {
  A:'.###.|#...#|#...#|#####|#...#|#...#|#...#', B:'####.|#...#|#...#|####.|#...#|#...#|####.', C:'.###.|#...#|#....|#....|#....|#...#|.###.',
  D:'####.|#...#|#...#|#...#|#...#|#...#|####.', E:'#####|#....|#....|####.|#....|#....|#####', F:'#####|#....|#....|####.|#....|#....|#....',
  G:'.###.|#...#|#....|#.###|#...#|#...#|.####', H:'#...#|#...#|#...#|#####|#...#|#...#|#...#', I:'#####|..#..|..#..|..#..|..#..|..#..|#####',
  J:'..###|...#.|...#.|...#.|#..#.|#..#.|.##..', K:'#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#', L:'#....|#....|#....|#....|#....|#....|#####',
  M:'#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#', N:'#...#|##..#|#.#.#|#.#.#|#..##|#...#|#...#', O:'.###.|#...#|#...#|#...#|#...#|#...#|.###.',
  P:'####.|#...#|#...#|####.|#....|#....|#....', Q:'.###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#', R:'####.|#...#|#...#|####.|#.#..|#..#.|#...#',
  S:'.####|#....|#....|.###.|....#|....#|####.', T:'#####|..#..|..#..|..#..|..#..|..#..|..#..', U:'#...#|#...#|#...#|#...#|#...#|#...#|.###.',
  V:'#...#|#...#|#...#|#...#|#...#|.#.#.|..#..', W:'#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#', X:'#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#',
  Y:'#...#|#...#|.#.#.|..#..|..#..|..#..|..#..', Z:'#####|....#|...#.|..#..|.#...|#....|#####',
  0:'.###.|#...#|#..##|#.#.#|##..#|#...#|.###.', 1:'..#..|.##..|..#..|..#..|..#..|..#..|.###.', 2:'.###.|#...#|....#|...#.|..#..|.#...|#####',
  3:'#####|...#.|..#..|...#.|....#|#...#|.###.', 4:'...#.|..##.|.#.#.|#..#.|#####|...#.|...#.', 5:'#####|#....|####.|....#|....#|#...#|.###.',
  6:'..##.|.#...|#....|####.|#...#|#...#|.###.', 7:'#####|....#|...#.|..#..|.#...|.#...|.#...', 8:'.###.|#...#|#...#|.###.|#...#|#...#|.###.',
  9:'.###.|#...#|#...#|.####|....#|...#.|.##..',
  '#':'.#.#.|.#.#.|#####|.#.#.|#####|.#.#.|.#.#.', '/':'....#|....#|...#.|..#..|.#...|#....|#....', '_':'.....|.....|.....|.....|.....|.....|#####',
  '-':'.....|.....|.....|#####|.....|.....|.....', '+':'.....|..#..|..#..|#####|..#..|..#..|.....', '.':'.....|.....|.....|.....|.....|.....|..#..',
  ' ':'.....|.....|.....|.....|.....|.....|.....',
  'а':'.....|.....|.###.|....#|.####|#...#|.####', 'д':'.....|.....|..##.|.#.#.|.#.#.|.#.#.|#####|#...#'
,
  '!':'..#..|..#..|..#..|..#..|..#..|.....|..#..',
  'Б':'#####|#....|#....|####.|#...#|#...#|####.', 'Г':'#####|#....|#....|#....|#....|#....|#....', 'Д':'.###.|.#.#.|.#.#.|.#.#.|.#.#.|#####|#...#',
  'Ж':'#.#.#|#.#.#|.###.|..#..|.###.|#.#.#|#.#.#', 'З':'.###.|#...#|....#|..##.|....#|#...#|.###.', 'И':'#...#|#...#|#..##|#.#.#|##..#|#...#|#...#',
  'Й':'.#.#.|#...#|#..##|#.#.#|##..#|#...#|#...#', 'Л':'..###|.#..#|.#..#|.#..#|.#..#|.#..#|#...#', 'П':'#####|#...#|#...#|#...#|#...#|#...#|#...#',
  'У':'#...#|#...#|#...#|.####|....#|#...#|.###.', 'Ф':'..#..|.###.|#.#.#|#.#.#|.###.|..#..|..#..', 'Ц':'#..#.|#..#.|#..#.|#..#.|#..#.|#####|....#',
  'Ч':'#...#|#...#|#...#|.####|....#|....#|....#', 'Ш':'#.#.#|#.#.#|#.#.#|#.#.#|#.#.#|#.#.#|#####', 'Щ':'#.#.#|#.#.#|#.#.#|#.#.#|#.#.#|#####|....#',
  'Ъ':'##...|.#...|.#...|.###.|.#..#|.#..#|.###.', 'Ы':'#...#|#...#|#...#|##..#|#.#.#|#.#.#|##..#', 'Ь':'#....|#....|#....|####.|#...#|#...#|####.',
  'Э':'.###.|#...#|....#|..###|....#|#...#|.###.', 'Ю':'#..#.|#.#.#|#.#.#|###.#|#.#.#|#.#.#|#..#.', 'Я':'.####|#...#|#...#|.####|..#.#|.#..#|#...#'
}; for (const k in src) V.F[k] = src[k].split('|');
  Object.entries({Е:'E',Ё:'E',А:'A',В:'B',К:'K',М:'M',Н:'H',О:'O',Р:'P',С:'C',Т:'T',Х:'X'}).forEach(([c, l]) => V.F[c] = V.F[l]); })();
V.glyph = ch => V.F[ch] || V.F[ch.toUpperCase()] || V.F[' '];
V.tpath = (str, x, y, px) => { let d = '', cx = x;
  for (const ch of str) { V.glyph(ch).forEach((row, ri) => { let c = 0; while (c < 5) { if (row[c] === '#') { let e = c; while (e < 5 && row[e] === '#') e++;
    d += `M${cx + c * px} ${y + ri * px}h${(e - c) * px}v${px}h${-(e - c) * px}z`; c = e; } else c++; } }); cx += 6 * px; }
  return d; };
V.textW = (s, px) => [...s].length * 6 * px - px;
V.text = (s, x, y, px, f) => `<path d="${V.tpath(s, x, y, px)}" fill="${f}"/>`;
V.btext = (s, x, y, px, o = {}) => { const dp = o.depth ?? Math.max(5, Math.round(px * 0.75)), h = Math.ceil(dp / 2);
  const a = V.tpath(s, x + h, y + h, px) + V.tpath(s, x + dp, y + dp, px), b = V.tpath(s, x, y, px);
  return `<path d="${a}" fill="${V.OL}" stroke="${V.OL}" stroke-width="6"/><path d="${a}" fill="${o.side ?? V.C.greyL}"/>` +
         `<path d="${b}" fill="${V.OL}" stroke="${V.OL}" stroke-width="6"/><path d="${b}" fill="${o.face ?? V.C.white}"/>`; };

V.button = (x, y, w, h, m, label, pressed, px = 5) => { const s = 8, dep = pressed ? 6 : 12, hw = Math.round(w * 0.3);
  let out = `<path d="${V.notch(x, y, w, h, s)}" fill="${m.d}" stroke="${V.OL}" stroke-width="3"/><path d="${V.notch(x + 1.5, y + 1.5, w - 3, h - dep - 1.5, s - 1.5)}" fill="${m.b}"/>` +
    `<path d="M${x + 10} ${y + 9}h${hw}v5h${-hw + 5}v5h-5z" fill="${m.h}"/>`;
  if (label) { const tw = V.textW(label, px); out += V.btext(label, Math.round(x + w / 2 - tw / 2 - 2), Math.round(y + (h - dep) / 2 - 3.5 * px - 2), px, { face: V.C.white, side: m.d, depth: 5 }); }
  return out; };

// exploded parts sheet with labels and pivot dots
V.parts = groups => { const pad = 24, gap = 28, top = 24; let x = pad; const items = [];
  const maxH = Math.max(...groups.map(g => g.bb[3] - g.bb[1]));
  for (const g of groups) { const bw = g.bb[2] - g.bb[0], bh = g.bb[3] - g.bb[1], lab = g.id.toUpperCase(), lw = V.textW(lab, 2), sw = Math.max(bw, lw);
    const dx = Math.round(x + (sw - bw) / 2 - g.bb[0]), dy = Math.round(top + maxH - bh - g.bb[1]);
    let s = `<g transform="translate(${dx} ${dy})">${g.svg()}`;
    if (g.pivot) s += `<circle cx="${g.pivot[0]}" cy="${g.pivot[1]}" r="4" fill="${V.C.crys}" stroke="${V.OL}" stroke-width="2"/>`;
    s += '</g>' + V.text(lab, Math.round(x + (sw - lw) / 2), Math.round(top + maxH + 14), 2, V.OL); items.push(s); x += sw + gap; }
  const W = Math.round(x - gap + pad), H = Math.round(top + maxH + 28 + pad);
  return { w: W, h: H, svg: V.svg(W, H, `<rect width="${W}" height="${H}" fill="${V.C.bone}"/>\n` + items.join('\n')) }; };

// multi-colour pixel bitmap with merged 3px silhouette outline
V.BM = { k:V.C.outline, w:V.C.white, b:V.C.bone, n:V.C.boneD, l:V.C.greyL, g:V.C.grey, G:V.C.greyD, y:V.C.yel, Y:V.C.yelD, o:V.C.org, O:V.C.orgD,
  d:V.C.wood, D:V.C.woodD, p:V.C.pink, u:V.C.blue, R:V.C.red, s:V.C.sky, L:V.C.grassL, e:V.C.grass, E:V.C.grassD, C:V.C.caveD, c:V.C.crys, t:V.C.teal, v:V.C.slime, Z:V.C.zom, x:V.C.zomD };
V.bitmap = (rows, ox, oy, px, map = V.BM) => { let sil = ''; const by = {};
  rows.forEach((row, ri) => { let c = 0; while (c < row.length) { if (row[c] === '.') { c++; continue; } let e = c; while (e < row.length && row[e] !== '.') e++;
    sil += `M${ox + c * px} ${oy + ri * px}h${(e - c) * px}v${px}h${-(e - c) * px}z`;
    let a = c; while (a < e) { const k = row[a]; let b = a; while (b < e && row[b] === k) b++; by[k] = (by[k] || '') + `M${ox + a * px} ${oy + ri * px}h${(b - a) * px}v${px}h${-(b - a) * px}z`; a = b; } c = e; } });
  let out = `<path d="${sil}" fill="${V.OL}" stroke="${V.OL}" stroke-width="6"/>`;
  for (const k in by) if (k !== 'k') out += `<path d="${by[k]}" fill="${map[k]}"/>`; return out; };
V.icon = (rows, size = 96, pad = 6) => { const w = Math.max(...rows.map(r => r.length)), h = rows.length, px = Math.floor((size - 2 * pad) / Math.max(w, h));
  return V.bitmap(rows, Math.round((size - w * px) / 2), Math.round((size - h * px) / 2), px); };
// voxel logo letters: extruded block text + per-cube highlight
V.vtext = (s, x, y, px, o = {}) => { let hi = '', cx = x; const hs = Math.round(px * 0.28), hi0 = Math.round(px * 0.18);
  for (const ch of s) { V.glyph(ch).forEach((row, ri) => { for (let c = 0; c < 5; c++) if (row[c] === '#') hi += `M${cx + c * px + hi0} ${y + ri * px + hi0}h${hs}v${hs}h${-hs}z`; }); cx += 6 * px; }
  return V.btext(s, x, y, px, { face: o.face, side: o.side, depth: o.depth ?? Math.round(px * 0.6) }) + `<path d="${hi}" fill="${o.hi ?? V.C.white}"/>`; };
V.inner = svg => svg.replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
V.pick = (svg, id) => (svg.match(new RegExp('<g id="' + id + '"[^>]*>[\\s\\S]*?</g>')) || [''])[0];
V.tint = (svg, col) => svg.replace(/(<g id="team_accent"[^>]*>)([\s\S]*?)(<\/g>)/, (m, a, b, c) => a + b.split('#FFFFFF').join(col) + c);
