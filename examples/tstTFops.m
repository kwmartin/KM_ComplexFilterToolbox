warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');
exmpl;
X0=X2o;
rmvlOrdr = [1, -1];
rmvlTypes = [8, 4];
if w_shift == 0
    [lddr, fail] = doRmvls(rmvlTypes, rmvlOrdr, X0, wps, ni)
    dispLddr(lddr)
    lim = [-10 10 -40 1];
    [gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
    C1 = lddr.ladderElems(1).C;
    L2 = lddr.ladderElems(2).L;
    C2 = lddr.ladderElems(2).C;
    C3 = lddr.ladderElems(3).C;
    yf1 = tf([C1 0], [1]);
    zf2 = tf([L2, 0], [L2*C2, 0, 1]);
    zf3 = tf([1], [C3, 1]);
    y23 = 1/(zf2 + zf3);
    zin1 = 1/(yf1 + y23);
end
e = zero2zpk(E);
f = zero2zpk(F);
zin_n = add_zpk(e, -f);
zin_p = invert_zpk(add_zpk(e, f));
zin = mult_zpk(zin_n, zin_p);


% rfl = zpk(F, E, -1);
% zin = simpl((1 + rfl)/(1 - rfl));
% zin_n = add_zpk(gain2zpk(1), rfl);
% zin_p = add_zpk(gain2zpk(1), -rfl);
% zin_p_inv = invert_zpk(zin_p);
% zin_tmp = mult_zpk(zin_n, zin_p_inv);
% zin = zin2;
rmvPl = @(p, wp) p(find(abs((p - wp)) > 1e-6));
yin = invert_zpk(zin);
[elem1, elem2, Y2, Y3] = rmvCmplx(yin, P(1))
[elem3, elem4, Y4, Y5] = rmvCmplx(Y3, P(2))
H1 = simpl((1/(1+tf(yin))));
H2 = simpl(Y2/(Y2 + tf(Y3)));
H3 = simpl(Y4/(Y4 + tf(Y5)));
H_ = minreal(simpl(H1*H2*H3), 1e-5)
H = simpl(H)

s = tf('s');
Ytst = simpl(X1 + 1/(K2/(s - P(1)) + 1/(tf(X3) + tf(1/(K4/(s - P(2)) + Z5)))));

X0=zin;
rmvlOrdr = [1, 2, -1];
rmvlTypes = [12, 12, 10];
zpk(X0)

[lddr, fail] = doCmplxRmvls(rmvlTypes, rmvlOrdr, X0, P, ni)
lim = [-8.5 11.5 -40 0.5];
lddr.R2 = 1e20;
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
