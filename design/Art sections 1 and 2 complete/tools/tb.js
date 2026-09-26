V.tb = (g, x, y, w, d, h, m, o = {}) => { g.rect(x, y, w, d + h, m.d);
  g.fill(`M${x + 1.5} ${y + 1.5}h${w - 3}v${d - 1.5}h${-(w - 3)}z`, o.top ?? m.b);
  if (w >= 16 && d >= 10 && o.hi !== false) { const hw = Math.max(5, Math.round(w * 0.28)); g.fill(`M${x + 5} ${y + 5}h${hw}v4h${-hw + 4}v4h-4z`, m.h); }
  if (o.tex) { const R = V.rng(Math.round(x * 13 + y * 7 + w)); let p = ''; for (let k = 0; k < o.tex; k++) p += `M${Math.round(x + 8 + R() * Math.max(0, w - 20))} ${Math.round(y + 8 + R() * Math.max(0, d - 16))}h4v4h-4z`; g.fill(p, o.texC ?? m.d); }
  if (o.ftex && h >= 14) { const R = V.rng(Math.round(x * 3 + y)); let p = ''; for (let k = 0; k < o.ftex; k++) p += `M${Math.round(x + 6 + R() * Math.max(0, w - 16))} ${Math.round(y + d + 4 + R() * Math.max(0, h - 12))}h4v4h-4z`; g.fill(p, o.ftexC ?? V.shade(m.d, 0.85)); }
  return g; };