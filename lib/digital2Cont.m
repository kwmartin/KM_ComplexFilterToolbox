function [z, p, k] = digital2Cont(zd, pd, kd, fs)
% [z, p, k] = digital2Cont(zd, pd, kd, fs) converts discrete-time zero/pole/gain
% data to continuous-time zero/pole/gain data using the inverse bilinear
% (Tustin) transform s = (2/T)*(w-1)/(w+1), T = 1/fs -- the exact algebraic
% inverse of the pole/zero mapping used internally by the Signal Processing
% Toolbox's bilinear(). This mirrors cont2Digital.m/invrsTrnsfrmD.m, which
% use bilinear() rather than the Control Toolbox's c2d(...,'tustin') because
% the latter does not work correctly on complex-coefficient systems; the
% Control Toolbox's d2c(...,'tustin') shares the same underlying machinery
% and is expected to have the same problem, so this function exists as its
% complex-safe replacement.
%
% zd, pd are the discrete zeros/poles, kd is the discrete gain, fs is the
% sample rate (T = 1/fs), matching bilinear(z,p,k,fs)'s own argument order.
%
% A discrete zero at exactly z=-1 maps to s=infinity and is dropped from the
% result: bilinear()'s forward transform pads the shorter of its zero/pole
% list with roots at z=-1 to equalize the counts, so this is the expected
% case when inverting its output. A discrete pole at z=-1 is unusual (it
% maps to a pole at infinity) and triggers a warning rather than a silent
% drop. If the original (undropped) zero/pole counts differ, the leftover
% algebraic factor is realized as extra root(s) at the fixed point s=2/T
% (the finite location that maps to z=infinity under this transform).
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2018  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

  T = 1/fs;
  tol = 1e-9;

  zd = zd(:);
  pd = pd(:);

  [z, ~] = mapRoots(zd, T, tol);
  [p, npDropped] = mapRoots(pd, T, tol);
  if npDropped > 0
      warning('digital2Cont:poleAtInfinity', ...
          '%d pole(s) at z=-1 map to s=infinity and were dropped; the result may not be a proper/realizable system.', npDropped);
  end

  % Leftover (1-sT/2)^(Np-Nz) factor from the original (undropped) counts:
  % realized as extra roots at the fixed point s=2/T (z=infinity). This is a
  % no-op in the common case where zd/pd already have equal length (e.g.
  % straight out of bilinear()).
  nExtra = length(pd) - length(zd);
  if nExtra > 0
      z = [z; repmat(2/T, nExtra, 1)];
  elseif nExtra < 0
      p = [p; repmat(2/T, -nExtra, 1)];
  end

  % Solve for k by matching H(s) to H(z) at one safe evaluation point rather
  % than a symbolic gain formula (which picks up awkward extra factors
  % depending on how many roots sit exactly at z=-1 on each side) -- the
  % same evaluate-and-solve-for-gain approach used in setK.m.
  Z0 = pickSafePoint(zd, pd);
  s0 = (2/T)*(Z0-1)/(Z0+1);
  Hd = kd * prod(Z0 - zd) / prod(Z0 - pd);
  Hc_unscaled = prod(s0 - z) / prod(s0 - p);
  k = Hd / Hc_unscaled;
end

function [r, nDropped] = mapRoots(R, T, tol)
  atInf = abs(R + 1) < tol;
  nDropped = sum(atInf);
  R = R(~atInf);
  r = (2/T) * (R - 1) ./ (R + 1);
end

function Z0 = pickSafePoint(zd, pd)
  candidates = [0, 2, -2, 3j, -3j, 5, -5, 7j, -7j];
  allRoots = [zd; pd];
  for c = candidates
      if all(abs(c - allRoots) > 1e-6) && abs(c+1) > 1e-6
          Z0 = c;
          return
      end
  end
  error('digital2Cont:noSafePoint', 'digital2Cont: could not find a safe evaluation point; please specify one manually.');
end
