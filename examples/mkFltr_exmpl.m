exmpl;
rmvlOrdr = [1, -1, -1];
rmvlTypes = [8, 4, 3];
lddr1 = ladderClass();
[X3, elem1, elem2, type] = rmv2PolesS(X1, P(1), P(2));
lddr1.addElem(elem1);
lddr1.addElem(elem2);
[X4, elem3, type] = rmvSCmplx(X3);
lddr1.addElem(elem3);
[X5, elem4, type] = rmvSCmplx(X4);
lddr1.addElem(elem4);
lim = [-10 10 -40 1];
if w_shift == 0
  wps = [imag(P(2))];
  [lddr, fail] = doRmvls(rmvlTypes, rmvlOrdr, X1, wps, ni)
  dispLddr(lddr1)
  C1 = lddr.ladderElems(1).C;
  L2 = lddr.ladderElems(2).L;
  C2 = lddr.ladderElems(2).C;
  C3 = lddr.ladderElems(3).C;
  yf1 = tf([C1 0], [1]);
  zf2 = tf([L2, 0], [L2*C2, 0, 1]);
  zf3 = tf([1], [C3, 1]);
  y23 = 1/(zf2 + zf3);
  zin = 1/(yf1 + y23);
  [n, d] = tfdata(zin, 'v');
  [res, pls, rem] = residue(n, d);
  [gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
else
  [gn, db] = plot_lddr(H, lddr1,wp,ws,'b',lim);
end
