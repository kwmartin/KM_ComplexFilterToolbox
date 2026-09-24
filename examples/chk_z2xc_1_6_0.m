% Checks the band-centred conformal transform z2xc/xc2z on the
% dig_linPh_1_6_0 design: exact round trip, the group-delay identity
% gd_z(w) = gd_x(W)*(1 + t^2*W^2)/(2*t), and whether the Newton
% sensitivity matrix used for group-delay equalization (plSens in z) is
% better conditioned in x.

p = [-0.35 -0.3 -0.2 0.3 0.4 0.45];
px = [];
wp = [0.05 0.06];
ws = [-0.49999 -0.1 0.22 0.49999];
as = [20 20 20 20];
Ap = 2.0;
Ordr = 7;
deltGD = 0.25;

warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

% reproduce dsgnEquiRplGD up to the adaptP3 call, i.e. the filter H3 and
% band wp3 that group-delay equalization actually works on
[p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as);
H1 = LinPh_LssPls(Ordr, deltGD, Ap, 3);
[p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
H3 = freq_shiftd(H2, shftFctr);
wp3 = wp + shftFctr;
fprintf('band wp3 = [%.6f %.6f] cycles\n', wp3);

% 1) round trip z -> x -> z on a dense grid
[Hx, t, w0] = z2xc(H3, wp3);
H3rt = xc2z(Hx, wp3);
w = 2*pi*(-0.5:1e-4:0.5);
[lg0, ph0] = AnlzDH(H3, w);
[lg1, ph1] = AnlzDH(H3rt, w);
rtErr = max(abs(exp(lg1 + j*ph1) - exp(lg0 + j*ph0))./abs(exp(lg0 + j*ph0)));
fprintf('round trip: max relative |H| error        = %.3g\n', rtErr);

% 2) group-delay identity over (and a little beyond) the band
wb = 2*pi*linspace(wp3(1) - 0.5*diff(wp3), wp3(2) + 0.5*diff(wp3), 2001);
W = tan((wb - w0)/2)/t;
J = (1 + t^2*W.^2)/(2*t);
[~, ~, gdz] = AnlzDH(H3, wb);
[~, ~, gdx] = AnlzH(Hx, W);
gdErr = max(abs(gdx(:).*J(:) - gdz(:))./abs(gdz(:)));
fprintf('GD identity: max relative error           = %.3g\n', gdErr);

% 3) conditioning of the Newton sensitivity matrix at the GD extrema
[~, pz] = sortZPK(H3);
[~, pxx] = sortZPK(Hx);
wz = fndZeroCrs3(H3, wp3);
wz = wz(:);
Wz = tan((wz - w0)/2)/t;
Jz = (1 + t^2*Wz.^2)/(2*t);
np = length(pz);
Sz = plSens(pz, wz);
Sx = Sz; % same layout, including plSens's mirror-constraint row
for l = 1:np
    d2 = 1./((j*Wz - pxx(l)).^2);
    Sx(1:end-1, l) = Jz.*real(d2);
    Sx(1:end-1, l+np) = -Jz.*imag(d2);
end
colNrm = @(S) S./vecnorm(S);
spacing = @(r) min(abs(r(:) - r(:).') + diag(inf(length(r), 1)), [], 'all');
fprintf('%d extrema, %d poles\n', length(wz), np);
fprintf('%-34s %12s %12s\n', '', 'z', 'x');
fprintf('%-34s %12.3g %12.3g\n', 'min pole spacing', spacing(pz), spacing(pxx));
fprintf('%-34s %12.3g %12.3g\n', 'max pole distance to boundary', ...
    max(1 - abs(pz)), max(-real(pxx)));
fprintf('%-34s %12.3g %12.3g\n', 'min pole distance to boundary', ...
    min(1 - abs(pz)), min(-real(pxx)));
fprintf('%-34s %12.3g %12.3g\n', 'cond(sens)', cond(Sz), cond(Sx));
fprintf('%-34s %12.3g %12.3g\n', 'cond(sens), columns normalized', ...
    cond(colNrm(Sz)), cond(colNrm(Sx)));
fprintf('%-34s %12.3g %12.3g\n', 'cond(sens w/o constraint row)', ...
    cond(Sz(1:end-1, :)), cond(Sx(1:end-1, :)));
fprintf('%-34s %12.3g %12.3g\n', '  same, columns normalized', ...
    cond(colNrm(Sz(1:end-1, :))), cond(colNrm(Sx(1:end-1, :))));
a = 1;
