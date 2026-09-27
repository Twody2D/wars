const MK = {};
MK.OL = '#1B1B2F';
MK.mul = (...ms) => ms.reduce((m, n) => [m[0]*n[0]+m[2]*n[1], m[1]*n[0]+m[3]*n[1], m[0]*n[2]+m[2]*n[3], m[1]*n[2]+m[3]*n[3], m[0]*n[4]+m[2]*n[5]+m[4], m[1]*n[4]+m[3]*n[5]+m[5]]);
MK.R = (a, cx = 0, cy = 0) => { const r = a * Math.PI / 180, c = Math.cos(r), s = Math.sin(r); return [c, s, -s, c, cx - c*cx + s*cy, cy - s*cx - c*cy]; };
MK.T = (x, y) => [1, 0, 0, 1, x, y];
MK.S = (sx, sy = sx) => [sx, 0, 0, sy, 0, 0];
MK.ap = (m, [x, y]) => [m[0]*x + m[2]*y + m[4], m[1]*x + m[3]*y + m[5]];
MK.str = m => `matrix(${m.map(v => +v.toFixed(4)).join(' ')})`;
MK.place = (X, Y, s, flip, fx, fy, lean = 0) => MK.mul(MK.T(X, Y), MK.R(lean), MK.S(flip ? -s : s, s), MK.T(-fx, -fy));
MK.parse = s => { const g = {}, order = []; s.split('\n').forEach(l => { const m = l.match(/^<g id="([^"]+)"/); if (m) { g[m[1]] = l.trim(); order.push(m[1]); } }); return { g, order }; };
// o.rot: {id: [[a,cx,cy], ...inner→outer]}, o.add: {id: svg appended inside group}, o.team, o.hide, o.only
MK.build = (u, o = {}) => (o.only || u.order).filter(id => u.g[id] && !(o.hide || []).includes(id)).map(id => {
  let s = u.g[id];
  if (o.add && o.add[id]) s = s.slice(0, -4) + o.add[id] + '</g>';
  if (id === 'team_accent' && o.team) s = s.split('#FFFFFF').join(o.team);
  (o.rot && o.rot[id] || []).forEach(r => { s = `<g transform="rotate(${r.join(' ')})">${s}</g>`; });
  return s; }).join('');
MK.put = (m, inner, attrs = '') => `<g transform="${MK.str(m)}"${attrs}>${inner}</g>`;
const OL = MK.OL;
MK.FACE_Z = `<path d="M121.5 91.5h15v7h-15zM147.5 89.5h17v8h-17z" fill="#FFFFFF"/><path d="M127 95h9v10h-9zM155 93h9v12h-9z" fill="${OL}"/><path d="M128 96h3v3h-3zM156 94h3v3h-3z" fill="#FFFFFF"/>` +
  `<rect x="114" y="80" width="28" height="8" fill="${OL}" transform="rotate(16 128 84)"/><rect x="143" y="77" width="28" height="8" fill="${OL}" transform="rotate(-16 157 81)"/>` +
  `<path d="M122 113h48v6h-4v15h-40v-15h-4z" fill="${OL}" stroke="${OL}" stroke-width="3"/><path d="M127 117h7v6h-7zM137 117h7v6h-7zM147 117h7v6h-7zM157 117h7v6h-7z" fill="#FFFFFF"/>` +
  `<rect x="146" y="126" width="15" height="17" fill="#FF7AA8" stroke="${OL}" stroke-width="3"/><path d="M152 128v10" stroke="#D9557F" stroke-width="3"/>`;
MK.FACE_K = `<path d="M242 174h36v16h-36zM298 170h40v18h-40z" fill="#FFFFFF"/><path d="M254 184h16v20h-16zM314 182h18v24h-18z" fill="${OL}"/><path d="M256 186h5v5h-5zM316 184h5v5h-5z" fill="#FFFFFF"/>` +
  `<rect x="228" y="156" width="62" height="14" fill="${OL}" transform="rotate(17 259 163)"/><rect x="292" y="150" width="62" height="14" fill="${OL}" transform="rotate(-17 323 157)"/>` +
  `<path d="M244 224h100v10h-6v44h-88v-44h-6z" fill="${OL}"/><rect x="262" y="256" width="62" height="20" fill="#FF7AA8"/><path d="M256 234h12v14h-12zM320 234h12v14h-12zM262 262h10v12h-10zM314 262h10v12h-10z" fill="#FFFFFF"/>`;
MK.FACE_G = `<rect x="252" y="108" width="44" height="14" fill="#4E5368" stroke="${OL}" stroke-width="3" transform="rotate(16 274 115)"/><rect x="296" y="106" width="44" height="14" fill="#4E5368" stroke="${OL}" stroke-width="3" transform="rotate(-16 318 113)"/>` +
  `<path d="M274 156h62v34h-62z" fill="${OL}" stroke="${OL}" stroke-width="3"/><rect x="282" y="170" width="46" height="14" fill="#7FE7FF"/><path d="M282 159h8v8h-8zM320 159h8v8h-8z" fill="#FFFFFF"/>`;
MK.SWORD = `<rect x="137" y="182" width="10" height="24" fill="#A8703F" stroke="${OL}" stroke-width="3"/><path d="M134 214h16v106l-8 12l-8-12z" fill="#EEF3FF" stroke="${OL}" stroke-width="3"/>` +
  `<path d="M143.5 216h5v102h-5z" fill="#B8C3DA"/><path d="M137 220h3v84h-3z" fill="#FFFFFF"/><rect x="120" y="203" width="44" height="11" fill="#FFD23F" stroke="${OL}" stroke-width="3"/><rect x="139" y="205" width="6" height="7" fill="#7FE7FF"/>`;
MK.defs = extra => `<defs>
<filter id="blur6" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
<filter id="blur16" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="16"/></filter>
<filter id="blur40" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="40"/></filter>
<filter id="mblur" x="-30%" y="-10%" width="160%" height="120%"><feGaussianBlur stdDeviation="18 2"/></filter>
${['B:#9FE4FF', 'R:#FFC24A', 'W:#FFFFFF', 'C:#7FE7FF'].map(s => { const [k, c] = s.split(':'); return `<filter id="rim${k}" x="-20%" y="-20%" width="140%" height="140%"><feMorphology in="SourceAlpha" operator="dilate" radius="5" result="d"/><feGaussianBlur in="d" stdDeviation="7" result="b"/><feFlood flood-color="${c}"/><feComposite in2="b" operator="in" result="g"/><feOffset in="SourceAlpha" dx="0" dy="14" result="o"/><feGaussianBlur in="o" stdDeviation="10" result="ob"/><feFlood flood-color="#0B0A1A" flood-opacity="0.45"/><feComposite in2="ob" operator="in" result="sh"/><feMerge><feMergeNode in="sh"/><feMergeNode in="g"/><feMergeNode in="g"/><feMergeNode in="SourceGraphic"/></feMerge></filter>`; }).join('\n')}
<filter id="logo" x="-10%" y="-10%" width="120%" height="140%"><feMorphology in="SourceAlpha" operator="dilate" radius="4" result="d"/><feFlood flood-color="${OL}"/><feComposite in2="d" operator="in" result="o"/><feOffset in="o" dy="10" result="s"/><feGaussianBlur in="SourceAlpha" stdDeviation="14" result="gb"/><feFlood flood-color="#FFFFFF" flood-opacity="0.55"/><feComposite in2="gb" operator="in" result="glow"/><feMerge><feMergeNode in="glow"/><feMergeNode in="s"/><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<radialGradient id="burst"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.25" stop-color="#FFF4B0"/><stop offset="0.55" stop-color="#FFD23F" stop-opacity="0.55"/><stop offset="1" stop-color="#FFD23F" stop-opacity="0"/></radialGradient>
<radialGradient id="fireburst"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE066"/><stop offset="0.6" stop-color="#FF8A3D" stop-opacity="0.8"/><stop offset="1" stop-color="#FF4A4A" stop-opacity="0"/></radialGradient>
<radialGradient id="cglow"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="0.3" stop-color="#7FE7FF" stop-opacity="0.7"/><stop offset="1" stop-color="#7FE7FF" stop-opacity="0"/></radialGradient>
<radialGradient id="vign" cx="0.5" cy="0.5" r="0.75"><stop offset="0.55" stop-color="#0B0A1A" stop-opacity="0"/><stop offset="1" stop-color="#0B0A1A" stop-opacity="0.6"/></radialGradient>
${extra || ''}</defs>`;
MK.rays = (cx, cy, n, r, w, col, op, off = 0) => { let d = ''; for (let i = 0; i < n; i++) { const a = off + i * Math.PI * 2 / n, a1 = a - w / 2, a2 = a + w / 2;
  d += `M${cx.toFixed(1)} ${cy.toFixed(1)}L${(cx + r * Math.cos(a1)).toFixed(1)} ${(cy + r * Math.sin(a1)).toFixed(1)}L${(cx + r * Math.cos(a2)).toFixed(1)} ${(cy + r * Math.sin(a2)).toFixed(1)}Z`; }
  return `<path d="${d}" fill="${col}" opacity="${op}"/>`; };
MK.rng = s => () => { s |= 0; s = s + 0x6D2B79F5 | 0; let t = Math.imul(s ^ s >>> 15, 1 | s); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
MK.cube = (x, y, s, rot, top, side, face) => `<g transform="translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${rot.toFixed(0)})"><rect x="${-s/2}" y="${-s/2}" width="${s}" height="${s}" fill="${face}" stroke="${OL}" stroke-width="${Math.max(2, s / 12).toFixed(1)}"/><path d="M${-s/2+2} ${-s/2+2}h${s-4}v${s*0.22}h${-(s-4)}z" fill="${top}"/><path d="M${s/2-2-s*0.22} ${-s/2+2+s*0.22}h${s*0.22}v${s*0.78-4}h${-s*0.22}z" fill="${side}"/></g>`;
MK.debris = (cx, cy, n, r0, r1, s0, s1, pal, seed, ex = []) => { const R = MK.rng(seed); let o = ''; for (let i = 0; i < n; i++) { const a = R() * Math.PI * 2, r = r0 + R() * (r1 - r0), s = s0 + R() * (s1 - s0), p = pal[i % pal.length], rt = R() * 90;
  const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a); if (ex.some(([x0, y0, x1, y1]) => x > x0 && x < x1 && y > y0 && y < y1)) continue;
  o += MK.cube(x, y, s, rt, p[0], p[1], p[2]); } return o; };
MK.bolt = (pts, R, jit, seed) => { const rnd = MK.rng(seed); let d = `M${pts[0][0]} ${pts[0][1]}`; for (let i = 1; i < pts.length; i++) { const [x0, y0] = pts[i-1], [x1, y1] = pts[i];
  for (let k = 1; k <= R; k++) { const t = k / R, j = k === R ? 0 : (rnd() - 0.5) * jit; d += `L${(x0 + (x1 - x0) * t + j).toFixed(1)} ${(y0 + (y1 - y0) * t + j * 0.3).toFixed(1)}`; } } return d; };
MK.star = (cx, cy, r1, r2, n, rot = 0) => { let d = ''; for (let i = 0; i < n * 2; i++) { const r = i % 2 ? r2 : r1, a = rot + i * Math.PI / n; d += (i ? 'L' : 'M') + (cx + r * Math.cos(a)).toFixed(1) + ' ' + (cy + r * Math.sin(a)).toFixed(1); } return d + 'Z'; };
MK.dust = (cx, cy, n, spread, s0, s1, seed, col = '#E9E2CF') => { const R = MK.rng(seed); let o = ''; for (let i = 0; i < n; i++) { const x = cx + (R() - 0.5) * spread, y = cy - R() * spread * 0.25, r = s0 + R() * (s1 - s0);
  o += `<circle cx="${x.toFixed(0)}" cy="${y.toFixed(0)}" r="${r.toFixed(0)}" fill="${col}"/>`; } return `<g opacity="0.85">${o}</g>`; };
MK.render = async (svg, W, H, outs) => { const img = new Image(); img.src = URL.createObjectURL(new Blob([svg], { type: 'image/svg+xml' })); await img.decode();
  const base = createCanvas(W, H); base.getContext('2d').drawImage(img, 0, 0, W, H); const res = [];
  for (const [w, h] of outs) { if (w === W) { res.push(base); continue; } let src = base, cw = W, ch = H;
    while (cw / 2 >= w) { const c = createCanvas(Math.round(cw / 2), Math.round(ch / 2)); const x = c.getContext('2d'); x.imageSmoothingQuality = 'high'; x.drawImage(src, 0, 0, c.width, c.height); src = c; cw = c.width; ch = c.height; }
    const c = createCanvas(w, h); const x = c.getContext('2d'); x.imageSmoothingQuality = 'high'; x.drawImage(src, 0, 0, w, h); res.push(c); }
  return res; };
