const Z = MK.parse(await readFile('assets/units/unit_zombie.svg'));
const S = 512, OL = MK.OL;
const defs = MK.defs(`<radialGradient id="bgI" cx="0.5" cy="0.42" r="0.7"><stop offset="0" stop-color="#BFE6FF"/><stop offset="0.35" stop-color="#5FA0FF"/><stop offset="0.75" stop-color="#3A7BFF"/><stop offset="1" stop-color="#1A3FB0"/></radialGradient>`);
let b = defs + `<rect width="${S}" height="${S}" fill="url(#bgI)"/>` + MK.rays(256, 230, 18, 520, 0.12, '#FFFFFF', 0.16, 0.1);
// sword behind head, pointing up-right
const sw = MK.mul(MK.T(418, 452), MK.R(208), MK.S(2.5), MK.T(-142, -196));
b += `<g filter="url(#blur16)" opacity="0.8">${MK.put(sw, `<path d="M130 190h24v150h-24z" fill="#FFFFFF"/>`)}</g>`;
b += `<g filter="url(#rimW)">${MK.put(sw, MK.SWORD + `<rect x="130" y="172" width="24" height="26" fill="#7F9C80" stroke="${OL}" stroke-width="3"/>`)}</g>`;
const hP = MK.mul(MK.T(250, 272), MK.S(4.0), MK.T(-128, -92));
b += `<g filter="url(#rimW)">${MK.put(hP, MK.build(Z, { only: ['head', 'team_accent'], add: { head: MK.FACE_Z }, team: '#3A7BFF' }))}</g>`;
return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${b}</svg>`;
