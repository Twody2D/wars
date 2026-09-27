const K = MK.parse(await readFile('assets/bosses/boss_zombie_king.svg'));
const S = 512, OL = MK.OL;
const defs = MK.defs(`<radialGradient id="bgI" cx="0.5" cy="0.5" r="0.7"><stop offset="0" stop-color="#FFE9A0"/><stop offset="0.3" stop-color="#FF9A3D"/><stop offset="0.7" stop-color="#F03A3A"/><stop offset="1" stop-color="#8E1430"/></radialGradient>`);
let b = defs + `<rect width="${S}" height="${S}" fill="url(#bgI)"/>` + MK.rays(256, 300, 20, 560, 0.11, '#FFF4B0', 0.22, 0.05);
{ const R = MK.rng(3); let o = ''; for (let i = 0; i < 18; i++) { const x = 30 + R() * 452, y = 30 + R() * 452; if (x > 90 && x < 420 && y > 50 && y < 470) continue; o += MK.cube(x, y, 10 + R() * 14, R() * 90, '#FFFFFF', '#FF8A3D', '#FFE066'); } b += o; }
// roar lines
b += `<path d="M60 330L20 350M64 290L16 290M452 330L492 350M448 290L496 290" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round"/>`;
const hP = MK.mul(MK.T(256, 262), MK.S(1.55), MK.T(-240, -150));
b += `<g filter="url(#rimR)">${MK.put(hP, MK.build(K, { only: ['head', 'team_accent'], add: { head: MK.FACE_K }, team: '#FF4A4A' }))}</g>`;
return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${b}</svg>`;
