const P = async n => MK.parse(await readFile(n));
const Z = await P('assets/units/unit_zombie.svg'), SK = await P('assets/units/unit_skeleton.svg'), SL = await P('assets/units/unit_slime.svg'), SP = await P('assets/units/unit_spider.svg'), G = await P('assets/bosses/boss_stone_golem.svg');
const logo = (await readFile('assets/v2/brand/logo_en.svg')).replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '').replace(/<metadata>[\s\S]*?<\/metadata>/g, '');
const W = 1600, H = 940, OL = MK.OL, GY = 700;
const u = (U, X, Y, s, flip, o, fx = 128, fy = 240, lean = 0) => MK.put(MK.place(X, Y, s, flip, fx, fy, lean), MK.build(U, o));
const run = { leg_front: [[-26, 137, 198]], leg_back: [[22, 115, 198]] };
const defs = MK.defs(`<linearGradient id="sky" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8FD6FF"/><stop offset="0.38" stop-color="#6FB8F0"/><stop offset="0.62" stop-color="#4A3F78"/><stop offset="1" stop-color="#1E1A34"/></linearGradient>
<linearGradient id="grd" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6CCB4A"/><stop offset="0.42" stop-color="#5DB844"/><stop offset="0.58" stop-color="#5A5480"/><stop offset="1" stop-color="#342E52"/></linearGradient>
<linearGradient id="grdF" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3F9A36"/><stop offset="0.42" stop-color="#3A8A33"/><stop offset="0.58" stop-color="#3A3458"/><stop offset="1" stop-color="#211D38"/></linearGradient>
<linearGradient id="trailF" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF4A4A" stop-opacity="0"/><stop offset="0.5" stop-color="#FF8A3D" stop-opacity="0.8"/><stop offset="0.85" stop-color="#FFD23F"/><stop offset="1" stop-color="#FFFFFF"/></linearGradient>
<radialGradient id="sun"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFF6C0" stop-opacity="0.9"/><stop offset="1" stop-color="#FFF6C0" stop-opacity="0"/></radialGradient>`);
let b = defs + `<rect width="${W}" height="${H}" fill="url(#sky)"/>`;
b += `<circle cx="180" cy="120" r="260" fill="url(#sun)"/>`;
// meadow hills left
b += `<path d="M-10 ${GY}V520H90V470H220V430H340V480H460V440H560V500H640V${GY}Z" fill="#8FD86A" stroke="${OL}" stroke-width="4"/><path d="M-10 ${GY}V590H120V560H300V600H480V570H620V${GY}Z" fill="#5DB844" stroke="${OL}" stroke-width="4"/>`;
b += MK.cube(260, 200, 70, 0, '#FFFFFF', '#D6E6F5', '#F4FAFF') + MK.cube(320, 216, 50, 0, '#FFFFFF', '#D6E6F5', '#F4FAFF');
// cave right: wall, stalactites, crystals
b += `<path d="M960 ${GY}V430H1060V380H1180V330H1320V380H1460V340H1610V${GY}Z" fill="#3A3458" stroke="${OL}" stroke-width="4"/>`;
{ let d = ''; [[1000, 90, 60], [1110, 150, 50], [1250, 110, 70], [1400, 170, 56], [1530, 120, 64]].forEach(([x, h, w]) => { d += `M${x - w / 2} -10H${x + w / 2}V${h * 0.5}H${x + w / 4}V${h}H${x - w / 4}V${h * 0.5}H${x - w / 2}Z`; });
  b += `<path d="${d}" fill="#2B2740" stroke="${OL}" stroke-width="4"/>`; }
const crystal = (x, y, s) => `<circle cx="${x}" cy="${y - s * 0.6}" r="${s * 1.6}" fill="url(#cglow)" opacity="0.8"/>` + [[-0.45, 0.7, 0.28], [0, 1.2, 0.36], [0.42, 0.85, 0.26]].map(([dx, h, w]) => `<path d="M${x + dx * s - w * s / 2} ${y}V${y - h * s * 0.8}L${x + dx * s} ${y - h * s}L${x + dx * s + w * s / 2} ${y - h * s * 0.8}V${y}Z" fill="#7FE7FF" stroke="${OL}" stroke-width="4"/><path d="M${x + dx * s - w * s / 2 + 5} ${y - 6}V${y - h * s * 0.75}h6V${y - 6}z" fill="#FFFFFF"/>`).join('');
b += crystal(1080, 440, 70) + crystal(1500, 400, 90) + crystal(1380, 700, 60);
// ground
b += `<rect x="-10" y="${GY}" width="${W + 20}" height="${H - GY + 10}" fill="url(#grdF)"/><rect x="-10" y="${GY}" width="${W + 20}" height="46" fill="url(#grd)" stroke="${OL}" stroke-width="4"/>`;
// meteor trail + glow
const mx = 860, my = 410, ex = 860;
b += `<path d="M${mx - 70} ${my - 20}L1560 -140L1700 -40L${mx + 40} ${my + 70}Z" fill="url(#trailF)" filter="url(#blur16)"/><path d="M${mx - 40} ${my}L1560 -120L1640 -60L${mx + 20} ${my + 50}Z" fill="url(#trailF)"/>`;
b += `<circle cx="${ex}" cy="${GY + 20}" r="420" fill="url(#fireburst)" opacity="0.85"/>`;
// back row
b += `<g filter="url(#rimR)">${u(SL, 1500, 720, 1.05, true, { team: '#FF4A4A' })}</g>`;
b += `<g filter="url(#rimR)">${u(G, 1210, 960, 1.3, true, { rot: { arm_front: [[-55, 332, 214]], arm_back: [[-25, 176, 214]], leg_front: [[-12, 289, 384]], leg_back: [[12, 215, 384]] }, add: { head: MK.FACE_G }, team: '#FF4A4A' }, 256, 480, -4)}</g>`;
b += `<g filter="url(#rimB)">${u(SK, 140, 770, 1.55, false, { rot: { arm_front: [[-80, 141, 148]], weapon: [[-80, 141, 148]], arm_back: [[-70, 121, 148]] }, team: '#3A7BFF' })}</g>`;
// explosion
b += `<path d="${MK.star(ex, GY + 10, 230, 70, 10, 0.3)}" fill="#FFE066" stroke="#FF8A3D" stroke-width="8"/><path d="${MK.star(ex, GY + 10, 130, 44, 10, 0.6)}" fill="#FFFFFF"/>`;
b += `<g filter="url(#blur6)">${MK.dust(ex, GY + 90, 12, 520, 24, 50, 9, '#F2E4C4')}</g>`;
// meteor rock
b += `<g transform="translate(${mx} ${my}) rotate(24) scale(0.8)"><rect x="-80" y="-80" width="160" height="160" fill="#4E5368" stroke="${OL}" stroke-width="6"/><path d="M-76 -76h152v34h-152z" fill="#7A7F96"/><path d="M42 -42h34v118h-118v-34h84z" fill="#2B2740"/>` +
  `<path d="M-50 -20h40v14h-26v30h-14zM10 10h40v14h-14v26h-14v-26h-12z" fill="#FF8A3D"/><path d="M-46 -16h10v10h-10zM20 14h10v8h-10z" fill="#FFE066"/></g>`;
// spider + our zombie hero (front)
b += `<g filter="url(#rimR)">${u(Z, 1000, 820, 1.4, true, { rot: { ...run, arm_front: [[-60, 142, 148]], arm_back: [[-40, 116, 148]] }, add: { head: MK.FACE_Z }, team: '#FF4A4A' }, 128, 240, -8)}</g>`;
b += `<g filter="url(#rimB)">${u(SP, 285, 740, 0.9, false, { team: '#3A7BFF' }, 128, 240, 4)}</g>`;
b += `<g filter="url(#rimB)">${u(SL, 700, 935, 1.0, false, { team: '#3A7BFF' })}</g>`;
const zo = { rot: { ...run, arm_front: [[-95, 142, 148]], arm_back: [[40, 116, 148]] }, add: { head: MK.FACE_Z, arm_front: MK.SWORD }, team: '#3A7BFF' };
b += `<g opacity="0.25" filter="url(#mblur)">${u(Z, 330, 1000, 2.8, false, zo, 128, 240, 10)}</g>`;
b += `<g filter="url(#rimB)">${u(Z, 420, 1000, 2.8, false, zo, 128, 240, 10)}</g>`;
b += MK.debris(ex, GY - 60, 26, 120, 520, 20, 52, [['#B4E86A', '#3F9A36', '#6CCB4A'], ['#FFE066', '#CF5F1E', '#FF8A3D'], ['#6D6592', '#2B2740', '#474063'], ['#E0B080', '#6E4526', '#A8703F']], 31,
  [[250, 380, 620, 780], [950, 450, 1150, 660], [620, 560, 760, 700], [1050, 350, 1310, 620], [-10, 760, 300, 950], [1340, 780, 1610, 950], [540, 0, 1060, 200]]);
b += `<rect width="${W}" height="${H}" fill="url(#vign)"/>`;
b += `<g filter="url(#logo)"><g transform="translate(${800 - 300 * 0.82} 14) scale(0.82)">${logo}</g></g>`;
return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${b}</svg>`;
