function Imp = makeImped(L, wl, C, wc)
ZL = tf([L, j*wl], 1.0);
YC = tf([C, j*wc], 1.0);
if (L == 0) && (wl == 0)
  Imp = 1.0/YC;
else
  Imp = 1.0/(YC + 1.0/ZL);
end

