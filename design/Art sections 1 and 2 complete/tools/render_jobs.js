const MK = new Function('createCanvas', await readFile('tools/mkt.js') + ';return MK;')(createCanvas);
const AF = Object.getPrototypeOf(async function(){}).constructor;
for (const k of JOBS) {
  const svg = await new AF('MK', 'readFile', await readFile(`tools/cover_${k.toLowerCase()}.js`))(MK, readFile);
  const e = new DOMParser().parseFromString(svg, 'image/svg+xml').querySelector('parsererror'); if (e) throw new Error(k + ': ' + e.textContent.slice(0, 300));
  if (k.startsWith('I')) { const n = k.slice(1); const [m, t] = await MK.render(svg, 512, 512, [[512, 512], [64, 64]]);
    await saveFile(`assets/store/store_icon_${n}.png`, m); await saveFile(`assets/store/test/store_icon_${n}_64.png`, t); }
  else { const [m, s, t] = await MK.render(svg, 1600, 940, [[1600, 940], [800, 470], [200, 118]]);
    await saveFile(`assets/store/store_cover_${k}_master.png`, m); await saveFile(`assets/store/store_cover_${k}.png`, s); await saveFile(`assets/store/test/store_cover_${k}_200.png`, t); }
}
