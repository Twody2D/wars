const P = async n => MK.parse(await readFile(n));
const Z = await P('assets/units/unit_zombie.svg'), BB = await P('assets/units/unit_barrel_bomber.svg'), G = await P('assets/bosses/boss_stone_golem.svg');
const logo = (await readFile('assets/v2/brand/logo_en.svg')).replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '').replace(/<metadata>[\s\S]*?<\/metadata>/g, '');
const W = 1600, H = 940, OL = MK.OL;
const mix = (h, t, to = [30, 26, 52]) => { const n = parseInt(h.slice(1), 16), c = [(n >> 16) & 255, (n >> 8) & 255, n & 255]; return '#' + c.map((v, i) => Math.round(v + (to[i] - v) * t).toString(16).padStart(2, '0')).join(''); };
const dim = (s, t) => s.replace(/#[0-9A-Fa-f]{6}/g, h => h.toUpperCase() === OL ? h : mix(h, t));
const defs = MK.defs(`<linearGradient id="cave" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#15122A"/><stop offset="0.6" stop-color="#2E2850"/><stop offset="1" stop-color="#474063"/></linearGradient>
<linearGradient id="beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BFF4FF" stop-opacity="0.55"/><stop offset="1" stop-color="#7FE7FF" stop-opacity="0"/></linearGradient>
<linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5A5480"/><stop offset="1" stop-color="#231F3C"/></linearGradient>
<radialGradient id="fuse"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFE066"/><stop offset="1" stop-color="#FF8A3D" stop-opacity="0"/></radialGradient>`);
let b = defs + `<rect width="${W}" height="${H}" fill="url(#cave)"/>`;
// back crystals & walls
const crystal = (x, y, s, op = 1) => `<g opacity="${op}"><circle cx="${x}" cy="${y - s * 0.6}" r="${s * 1.7}" fill="url(#cglow)" opacity="0.7"/>` + [[-0.45, 0.7, 0.28], [0, 1.2, 0.36], [0.42, 0.85, 0.26]].map(([dx, h, w]) => `<path d="M${x + dx * s - w * s / 2} ${y}V${y - h * s * 0.8}L${x + dx * s} ${y - h * s}L${x + dx * s + w * s / 2} ${y - h * s * 0.8}V${y}Z" fill="#7FE7FF" stroke="${OL}" stroke-width="4"/><path d="M${x + dx * s - w * s / 2 + 5} ${y - 6}V${y - h * s * 0.75}h6V${y - 6}z" fill="#FFFFFF"/>`).join('') + '</g>';
{ let d = ''; [[80, 120, 90], [300, 70, 70], [560, 150, 80], [1380, 110, 90], [1540, 160, 70]].forEach(([x, h, w]) => { d += `M${x - w / 2} -10H${x + w / 2}V${h * 0.5}H${x + w / 4}V${h}H${x - w / 4}V${h * 0.5}H${x - w / 2}Z`; });
  b += `<path d="${d}" fill="#211D38" stroke="${OL}" stroke-width="4"/>`; }
b += `<path d="M-10 760V600H120V540H260V620H380V760Z" fill="#3A3458" stroke="${OL}" stroke-width="4"/><path d="M1230 760V560H1360V500H1500V580H1610V760Z" fill="#3A3458" stroke="${OL}" stroke-width="4"/>`;
b += crystal(160, 560, 80, 0.9) + crystal(1440, 520, 100, 0.9) + crystal(1300, 770, 60);
// god rays
b += `<g opacity="0.9">${[[900, 200, 1180, 520], [1020, 260, 1260, 620], [760, 120, 980, 420]].map(([x0, w0, x1, w1]) => `<path d="M${x0 - w0 / 2} -20H${x0 + w0 / 2}L${x1 + w1 / 2} ${H}H${x1 - w1 / 2}Z" fill="url(#beam)"/>`).join('')}</g>`;
b += `<rect x="-10" y="760" width="${W + 20}" height="200" fill="url(#floor)"/><path d="M-10 760H${W + 10}" stroke="${OL}" stroke-width="4"/>`;
// golem
const gP = MK.place(1080, 1070, 2.15, true, 256, 480, -3);
const gw = (p, r, op = 1) => { const q = MK.ap(gP, p); return `<circle cx="${q[0].toFixed(0)}" cy="${q[1].toFixed(0)}" r="${r}" fill="url(#cglow)" opacity="${op}"/>`; };
b += `<ellipse cx="1080" cy="1000" rx="420" ry="70" fill="#0B0A1A" opacity="0.5" filter="url(#blur16)"/>`;
b += gw([258, 30], 170, 0.9) + gw([285, 249], 150, 0.8);
b += `<g filter="url(#rimC)">${MK.put(gP, MK.build(G, { rot: { arm_front: [[-95, 332, 214]], arm_back: [[-120, 176, 214]] }, add: { head: MK.FACE_G }, team: '#FF4A4A' }))}</g>`;
b += gw([275, 133], 60, 0.9) + gw([317, 133], 60, 0.9) + gw([285, 249], 70, 0.6) + gw([305, 177], 50, 0.8);
// dust at golem feet
b += `<g filter="url(#blur6)">${MK.dust(1080, 930, 14, 700, 24, 56, 13, '#8D86B0')}</g>`;
// heroes, backlit
const zP = MK.place(470, 1020, 2.7, false, 128, 240, -4);
const zb = dim(MK.build(Z, { rot: { arm_front: [[-30, 142, 148]], arm_back: [[-128, 116, 148]], leg_front: [[-14, 137, 198]], leg_back: [[14, 115, 198]] }, add: { head: MK.FACE_Z, arm_back: `<g transform="translate(-26 0)">${MK.SWORD}</g>` }, team: '#3A7BFF' }), 0.18);
const zTip = MK.ap(MK.mul(zP, MK.R(-128, 116, 148), MK.R(-28, 116, 148)), [116, 332]);
b += `<circle cx="${zTip[0].toFixed(0)}" cy="${zTip[1].toFixed(0)}" r="120" fill="url(#cglow)"/>`;
b += `<path d="${MK.star(zTip[0], zTip[1], 70, 14, 4, 0)}" fill="#FFFFFF"/>`;
const bP = MK.place(740, 1000, 1.9, false, 128, 240, 3);
const fuse = MK.ap(bP, [141, 57]);
b += `<g filter="url(#rimC)">${MK.put(bP, dim(MK.build(BB, { rot: { leg_front: [[-16, 141, 212]], leg_back: [[16, 115, 212]] }, team: '#3A7BFF' }), 0.18))}</g>`;
b += `<circle cx="${fuse[0].toFixed(0)}" cy="${fuse[1].toFixed(0)}" r="90" fill="url(#fuse)"/>`;
{ const R = MK.rng(5); let o = ''; for (let i = 0; i < 12; i++) { const a = -Math.PI / 2 + (R() - 0.5) * 2.4, r = 30 + R() * 70; o += `<rect x="${(fuse[0] + r * Math.cos(a) - 5).toFixed(0)}" y="${(fuse[1] + r * Math.sin(a) - 5).toFixed(0)}" width="10" height="10" fill="${i % 2 ? '#FFE066' : '#FFFFFF'}"/>`; } b += o; }
b += `<g filter="url(#rimC)">${MK.put(zP, zb)}</g>`;
b += MK.debris(900, 600, 16, 120, 700, 18, 40, [['#A7ABBD', '#4E5368', '#7A7F96'], ['#FFFFFF', '#2FB5A8', '#7FE7FF']], 41, [[640, 200, 1300, 640], [300, 300, 640, 760], [-10, 760, 300, 950], [1340, 780, 1610, 950], [0, 0, 560, 230]]);
b += `<rect width="${W}" height="${H}" fill="url(#vign)"/>`;
b += `<g filter="url(#logo)"><g transform="translate(36 18) scale(0.8)">${logo}</g></g>`;
return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${b}</svg>`;
