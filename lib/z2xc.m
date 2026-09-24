function [Hx, t, w0] = z2xc(Hz, fb)
%   [Hx, t, w0] = z2xc(Hz, fb) transforms a discrete-time zpk model in the
%   z domain to the x domain using the band-centred conformal (Mobius)
%   transform
%       x = (1/t)*(z*exp(-j*w0) - 1)/(z*exp(-j*w0) + 1)
%   where fb = [f1 f2] is the band of interest in cycles/sample,
%   w0 = pi*(f1 + f2) and t = tan(pi*(f2 - f1)/2).
%
%   The unit circle maps to the imaginary axis x = j*W with
%   W = tan((w - w0)/2)/t, so the band [f1 f2] maps to W in [-1 1] and
%   z = -exp(j*w0) maps to infinity. |z| < 1 maps to the left-half plane.
%   The transform is linear-fractional (no square root), so each root in z
%   maps to exactly one root in x and all-pass sections stay all-pass.
%
%   The gain is exact (no numerical fitting): each factor (z - a) becomes
%   -(exp(j*w0) + a)*(x - xa)/(x - 1/t), so zeros at z = infinity (when
%   there are more poles than zeros) appear as zeros at x = 1/t.
%
%   Group delays at corresponding points are related by
%       gd_z(w) = gd_x(W) * (1 + t^2*W^2)/(2*t)
%   where gd_x is found using AnlzH(Hx, W). The inverse is xc2z.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2026  Kenneth Martin
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

  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  w0 = pi*(fb(1) + fb(2));
  t = tan(pi*(fb(2) - fb(1))/2);
  [z, p, k] = zpkdata(zpk(Hz), 'vector');
  [zx, kz] = mapRoots(z, w0, t);
  [px, kp] = mapRoots(p, w0, t);
  % every z-domain root contributes (x - 1/t)^(-1) for a zero and
  % (x - 1/t)^(+1) for a pole; the net power becomes roots at x = 1/t
  nInf = length(p) - length(z);
  if nInf > 0
      zx = [zx; (1/t)*ones(nInf, 1)];
  elseif nInf < 0
      px = [px; (1/t)*ones(-nInf, 1)];
  end
  Hx = zpk(zx, px, k*kz/kp);
end

function [xr, c] = mapRoots(r, w0, t)
%   maps z-domain roots r to x-domain roots xr; c is the product of the
%   constants each factor (z - r) contributes to the gain
  TOL = 1e-12;
  e = exp(j*w0);
  r = r(:);
  atInf = abs(r + e) < TOL; % z = -exp(j*w0) maps to x = infinity
  rf = r(~atInf);
  xr = ((rf/e - 1)./(rf/e + 1))/t;
  c = prod(-(e + rf)) * (-2*e/t)^sum(atInf);
end
