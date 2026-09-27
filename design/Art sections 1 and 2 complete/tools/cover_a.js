const Z = MK.parse(await readFile('assets/units/unit_zombie.svg'));
const K = MK.parse(await readFile('assets/bosses/boss_zombie_king.svg'));
const logo = (await readFile('assets/v2/brand/logo_en.svg')).replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '').replace(/<metadata>[\s\S]*?<\/metadata>/g, '');
const W = 1600, H = 940;
const zA = -100, zP = MK.place(430, 990, 3.4, false, 128, 240, 6);
const zRot = { arm_front: [[zA, 142, 148]], arm_back: [[-40, 116, 148]], leg_front: [[-22, 137, 198]], leg_back: [[18, 115, 198]] };
const zArm = MK.mul(zP, MK.R(zA, 142, 148), MK.R(-28, 142, 148));
const zShoulder = MK.ap(zP, [142, 148]), zTip = MK.ap(zArm, [142, 332]), zClash = MK.ap(zArm, [142, 300]);
const kS = 1.75, kY = 990, kW = [65, 340, 376];
const kLog = (a, X) => MK.mul(MK.place(X, kY, kS, true, 256, 480, -5), MK.R(a, 304, 292), MK.R(...kW), MK.R(25, 340, 376));
let best = null; for (let a = -90; a <= 30; a += 1) { const p = MK.ap(kLog(a, 0), [340, 230]); const err = Math.abs(p[1] - zClash[1]); if (!best || err < best.e) best = { a, e: err, p }; }
const kA = best.a, kX = zClash[0] - best.p[0] + 30;
const kP = MK.place(kX, kY, kS, true, 256, 480, -5);
const kRot = { arm_front: [[kA, 304, 292]], weapon: [kW, [kA, 304, 292]], arm_back: [[-35, 208, 292]], leg_front: [[-18, 282, 392]], leg_back: [[16, 222, 392]] };
const C = zClash;
const rT = Math.hypot(zTip[0] - zShoulder[0], zTip[1] - zShoulder[1]), aT = Math.atan2(zTip[1] - zShoulder[1], zTip[0] - zShoulder[0]);
const arcPts = (r, a0, a1, n = 24) => Array.from({ length: n + 1 }, (_, i) => { const a = a0 + (a1 - a0) * i / n; return [zShoulder[0] + r * Math.cos(a), zShoulder[1] + r * Math.sin(a)]; });
const outer = arcPts(rT + 10, aT - 1.5, aT), inner = arcPts(rT * 0.5, aT, aT - 1.5);
const trailD = 'M' + [...outer, ...inner].map(p => p.map(v => v.toFixed(1)).join(' ')).join('L') + 'Z';
const t0 = outer[0], t1 = outer[outer.length - 1];
const defs = MK.defs(`<linearGradient id="bgB" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6FB0FF"/><stop offset="0.6" stop-color="#2F63E8"/><stop offset="1" stop-color="#1A3FB0"/></linearGradient>
<linearGradient id="bgR" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF9A5A"/><stop offset="0.6" stop-color="#F03A3A"/><stop offset="1" stop-color="#B01E36"/></linearGradient>
<linearGradient id="trail" gradientUnits="userSpaceOnUse" x1="${t0[0].toFixed(0)}" y1="${t0[1].toFixed(0)}" x2="${t1[0].toFixed(0)}" y2="${t1[1].toFixed(0)}"><stop offset="0" stop-color="#3A7BFF" stop-opacity="0"/><stop offset="0.6" stop-color="#5FB8FF" stop-opacity="0.75"/><stop offset="1" stop-color="#E6FAFF" stop-opacity="1"/></linearGradient>`);
const sx = +C[0].toFixed(1), sy = +C[1].toFixed(1);
const L0 = [sx + 330, -20], L1 = [sx - 330, H + 20];
let b = defs;
b += `<rect width="${W}" height="${H}" fill="url(#bgB)"/>`;
b += `<path d="M${L0[0]} ${L0[1]}L${W + 20} -20L${W + 20} ${H + 20}L${L1[0]} ${L1[1]}Z" fill="url(#bgR)"/>`;
b += MK.rays(sx, sy, 28, 1600, 0.09, '#FFFFFF', 0.13, 0.1);
{ const R = MK.rng(4); let d = ''; for (let i = 0; i < 40; i++) { const a = R() * Math.PI * 2, r0 = 520 + R() * 200, r1 = r0 + 300 + R() * 400; d += `M${(sx + r0 * Math.cos(a)).toFixed(0)} ${(sy + r0 * Math.sin(a)).toFixed(0)}L${(sx + r1 * Math.cos(a)).toFixed(0)} ${(sy + r1 * Math.sin(a)).toFixed(0)}`; }
  b += `<path d="${d}" stroke="#FFFFFF" stroke-width="5" opacity="0.35" stroke-linecap="round"/>`; }
const bolt = MK.bolt([L0, [sx, sy], L1], 9, 90, 7);
b += `<path d="${bolt}" fill="none" stroke="#FFF6C0" stroke-width="60" opacity="0.55" filter="url(#blur16)"/><path d="${bolt}" fill="none" stroke="${MK.OL}" stroke-width="20" stroke-linejoin="round"/><path d="${bolt}" fill="none" stroke="#FFFFFF" stroke-width="11" stroke-linejoin="round"/>`;
b += `<ellipse cx="800" cy="1010" rx="900" ry="140" fill="#0B0A1A" opacity="0.35" filter="url(#blur40)"/>`;
b += `<g filter="url(#blur6)">${MK.dust(360, 975, 16, 380, 18, 44, 3)}${MK.dust(kX, 975, 16, 420, 18, 48, 5)}</g>`;
b += `<circle cx="${sx}" cy="${sy}" r="360" fill="url(#burst)" opacity="0.8"/>`;
const zombie = MK.put(zP, MK.build(Z, { rot: zRot, add: { head: MK.FACE_Z, arm_front: MK.SWORD }, team: '#3A7BFF' }));
const king = MK.put(kP, MK.build(K, { rot: kRot, add: { head: MK.FACE_K }, team: '#FF4A4A' }));
b += `<path d="${trailD}" fill="url(#trail)" filter="url(#blur6)"/><path d="${trailD}" fill="url(#trail)" opacity="0.8"/>`;
b += `<g filter="url(#rimR)">${king}</g>`;
b += `<g filter="url(#rimB)">${zombie}</g>`;
b += `<circle cx="${sx}" cy="${sy}" r="150" fill="url(#burst)"/>`;
b += `<path d="${MK.star(sx, sy, 150, 34, 8, 0.2)}" fill="#FFFFFF" stroke="#FFD23F" stroke-width="6"/><path d="${MK.star(sx, sy, 80, 22, 8, 0.6)}" fill="#FFF4B0"/>`;
{ const R = MK.rng(11); let o = ''; for (let i = 0; i < 26; i++) { const a = R() * Math.PI * 2, r = 120 + R() * 200, s = 10 + R() * 18; const x = sx + r * Math.cos(a), y = sy + r * Math.sin(a); if ((x < 690 && y > 380) || (x > 1080 && y > 300)) continue;
  o += `<path d="M${(x - Math.cos(a) * s * 3).toFixed(0)} ${(y - Math.sin(a) * s * 3).toFixed(0)}L${x.toFixed(0)} ${y.toFixed(0)}" stroke="#FFE680" stroke-width="${(s / 3).toFixed(0)}" stroke-linecap="round"/>`; o += MK.cube(x, y, s, R() * 90, '#FFFFFF', '#FFD23F', '#FFF4B0'); }
  b += `<g>${o}</g>`; }
b += MK.debris(sx, sy + 40, 12, 260, 520, 22, 46, [['#A6C29E', '#56705A', '#7F9C80'], ['#E0B080', '#6E4526', '#A8703F'], ['#A7ABBD', '#4E5368', '#7A7F96']], 21, [[280, 260, 700, 680], [1060, 160, 1540, 680]]);
b += `<rect width="${W}" height="${H}" fill="url(#vign)"/>`;
b += `<g filter="url(#logo)"><g transform="translate(${800 - 300 * 0.82} 14) scale(0.82)">${logo}</g></g>`;
return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${b}</svg>`;
