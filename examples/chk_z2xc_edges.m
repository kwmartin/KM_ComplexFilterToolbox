% Edge-case checks for z2xc/xc2z: more poles than zeros, more zeros
% than poles, a root exactly at z = -exp(j*w0) (maps to x = infinity), an
% off-centre complex band, and an all-pass section staying all-pass.

warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

fb = [0.05 0.06];
w0 = pi*sum(fb);
e = exp(j*w0);
t = tan(pi*diff(fb)/2);
pp = 0.97*exp(j*(w0 + [-0.02 -0.005 0.01 0.03]));
wAll = 2*pi*(-0.5:1e-3:0.5);
cases = {
    'np > nz',                 zpk(0.9*exp(j*[1 2]), pp, 0.3+0.1j, 1)
    'nz > np',                 zpk(0.9*exp(j*(1:5)), pp, 0.3, 1)
    'zero at -exp(j*w0)',      zpk([-e; 0.5], pp, 1, 1)
    'pole at -exp(j*w0)',      zpk(0.5, [pp.'; -e], 1, 1)
    'all-pass',                zpk(1./conj(pp), pp, 1, 1)
    };
fprintf('%-22s %12s %12s %12s %12s\n', 'case', 'roots/gain', 'round trip', 'H(z)=H(x)', 'GD identity');
for i = 1:size(cases, 1)
    Hz = cases{i, 2};
    Hx = z2xc(Hz, fb);
    Hrt = xc2z(Hx, fb);
    [z0, p0, k0] = zpkdata(Hz, 'vector');
    [z1, p1, k1] = zpkdata(Hrt, 'vector');
    % nearest-root matching: sort() can pair equal-magnitude roots differently
    rootErr = max([rootDist(z0, z1), rootDist(p0, p1), abs(k0 - k1)/abs(k0)]);
    % skip frequencies on top of a unit-circle pole (the -exp(j*w0) case)
    w = wAll(min(abs(exp(j*wAll(:)) - p0.'), [], 2) > 1e-6);
    [lg0, ph0, gd0] = AnlzDH(Hz, w);
    [lg1, ph1] = AnlzDH(Hrt, w);
    H0 = exp(lg0 + j*ph0);
    rt = max(abs(exp(lg1 + j*ph1) - H0)./abs(H0));
    W = tan((w - w0)/2)/t;
    ok = abs(W) < 1e6; % skip the point that maps to x = infinity
    [lgx, phx, gdx] = AnlzH(Hx, W(ok));
    hx = max(abs(exp(lgx(:) + j*phx(:)) - H0(ok).')./abs(H0(ok).'));
    J = (1 + t^2*W(ok).^2)/(2*t);
    gdErr = max(abs(gdx(:).*J(:) - gd0(ok).')./max(abs(gd0(ok).'), 1));
    fprintf('%-22s %12.3g %12.3g %12.3g %12.3g\n', cases{i, 1}, rootErr, rt, hx, gdErr);
end
Hx = z2xc(cases{5, 2}, fb);
[zx, px] = zpkdata(Hx, 'vector');
fprintf('all-pass in x: max |zero + conj(pole)| = %.3g, max Re(pole) = %.3g\n', ...
    rootDist(zx, -conj(px)), max(real(px)));
a = 1;

function d = rootDist(a, b)
%   largest distance from a root in a to the nearest root in b; inf if the
%   root counts differ
    if length(a) ~= length(b)
        d = inf;
    elseif isempty(a)
        d = 0;
    else
        d = max(min(abs(a(:) - b(:).'), [], 2));
    end
end
