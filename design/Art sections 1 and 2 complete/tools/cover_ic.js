const Z = MK.parse(await readFile('assets/units/unit_zombie.svg'));
const K = MK.parse(await readFile('assets/bosses/boss_zombie_king.svg'));
const S = 512, OL = MK.OL;
const defs = MK.defs(`<linearGradient id="bB" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7FC0FF"/><stop offset="1" stop-color="#1F4AC8"/></linearGradient>
<linearGradient id="bR" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFA060"/><stop offset="1" stop-color="#C21E36"/></linearGradient>`);
let b = defs + `<rect width="${S}" height="${S}" fill="url(#bB)"/><path d="M330 -10H522V522H190Z" fill="url(#bR)"/>`;
const bolt = MK.bolt([[330, -10], [258, 250], [190, 522]], 6, 50, 3);
b += `<path d="${bolt}" fill="none" stroke="#FFF6C0" stroke-width="34" opacity="0.6" filter="url(#blur16)"/><path d="${bolt}" fill="none" stroke="${OL}" stroke-width="14" stroke-linejoin="round"/><path d="${bolt}" fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linejoin="round"/>`;
const zP = MK.mul(MK.T(140, 290), MK.S(2.35), MK.T(-128, -92));
b += `<g filter="url(#rimB)">${MK.put(zP, MK.build(Z, { only: ['head', 'team_accent'], add: { head: MK.FACE_Z }, team: '#3A7BFF' }))}</g>`;
const kP = MK.mul(MK.T(368, 282), MK.S(-0.88, 0.88), MK.T(-240, -150));
b += `<g filter="url(#rimR)">${MK.put(kP, MK.build(K, { only: ['head', 'team_accent'], add: { head: MK.FACE_K }, team: '#FF4A4A' }))}</g>`;
b += `<circle cx="256" cy="150" r="70" fill="url(#burst)"/><path d="${MK.star(256, 150, 46, 12, 6, 0.3)}" fill="#FFFFFF" stroke="#FFD23F" stroke-width="3"/>`;
return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${b}</svg>`;
