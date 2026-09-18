% Verification for lib/digital2Cont.m -- the inverse bilinear transform.
%
% Toolbox for the Design of Complex Filters
% Copyright (C) 2018  Kenneth Martin

fs = 1;
T = 1/fs;
tol = 1e-8;
nFail = 0;

fprintf('--- Test 1: round-trip, real coefficients ---\n');
z0 = [-1+0.5j; -1-0.5j];
p0 = [-0.2+3j; -0.2-3j; -1.5];
k0 = 2.3;
[zd, pd, kd] = bilinear(z0, p0, k0, fs);
[z1, p1, k1] = digital2Cont(zd, pd, kd, fs);
e = max([matchErr(z0,z1), matchErr(p0,p1), abs(k0-k1)/abs(k0)]);
fprintf('max relative error = %.3g\n', e);
if e > tol, nFail = nFail+1; fprintf('FAIL\n'); else fprintf('PASS\n'); end

fprintf('--- Test 2: round-trip, complex coefficients ---\n');
z0 = [1+2j; -0.3+0.1j];
p0 = [-0.5+4j; -0.7-1j; -2+0.5j];
k0 = 1.7 - 0.9j;
[zd, pd, kd] = bilinear(z0, p0, k0, fs);
[z1, p1, k1] = digital2Cont(zd, pd, kd, fs);
e = max([matchErr(z0,z1), matchErr(p0,p1), abs(k0-k1)/abs(k0)]);
fprintf('max relative error = %.3g\n', e);
if e > tol, nFail = nFail+1; fprintf('FAIL\n'); else fprintf('PASS\n'); end

fprintf('--- Test 3: strictly-proper system forces z=-1 padding ---\n');
z0 = [0.5j]; % 1 zero
p0 = [-0.3+2j; -0.3-2j; -1.1]; % 3 poles -> bilinear pads 2 zeros at z=-1
[zd, pd, kd] = bilinear(z0, p0, 1.0, fs);
nAtMinus1 = sum(abs(zd+1) < 1e-9);
fprintf('discrete zeros at z=-1: %d (expect 2)\n', nAtMinus1);
[z1, p1, k1] = digital2Cont(zd, pd, kd, fs);
fprintf('recovered zero count: %d (expect 1)\n', length(z1));
e = max([matchErr(z0,z1), matchErr(p0,p1), abs(1.0-k1)/1.0]);
fprintf('max relative error = %.3g\n', e);
if e > tol || length(z1) ~= 1, nFail = nFail+1; fprintf('FAIL\n'); else fprintf('PASS\n'); end

fprintf('--- Test 4: count-imbalance path (no z=-1 roots) ---\n');
zd = [0.4+0.1j];
pd = [0.2+0.6j; -0.3+0.2j; 0.1-0.5j];
kd = 1.3;
[z1, p1, k1] = digital2Cont(zd, pd, kd, fs);
% 1 discrete zero maps to 1 finite continuous zero; the 2-root pole/zero
% count imbalance (3 poles vs 1 zero) adds 2 extra zeros at s=2/T -> 3 zeros
fprintf('zeros: %d, poles: %d (expect zeros=3, poles=3)\n', length(z1), length(p1));
% Verify H(s0) at test point s0 matches H(zd0) at the corresponding Z0
Z0 = 10; % arbitrary safe point away from any root and -1
s0 = (2/T)*(Z0-1)/(Z0+1);
Hd = kd*prod(Z0-zd)/prod(Z0-pd);
Hc = k1*prod(s0-z1)/prod(s0-p1);
e = abs(Hd-Hc)/abs(Hd);
fprintf('H(s0) vs H(Z0) relative error = %.3g\n', e);
if e > tol || length(z1) ~= 3 || length(p1) ~= 3, nFail = nFail+1; fprintf('FAIL\n'); else fprintf('PASS\n'); end

fprintf('\n%d test(s) failed\n', nFail);

function e = matchErr(a, b)
  a = sort(a(:), 'ComparisonMethod', 'real');
  b = sort(b(:), 'ComparisonMethod', 'real');
  if length(a) ~= length(b)
      e = Inf;
      return
  end
  e = max(abs(a-b))/max(abs(a));
end
