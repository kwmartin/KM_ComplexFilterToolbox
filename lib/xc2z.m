function Hz = xc2z(Hx, fb)
%   Hz = xc2z(Hx, fb) is the inverse of z2xc; it transforms a zpk model in
%   the x domain back to the discrete-time z domain using
%       z = exp(j*w0)*(1 + t*x)/(1 - t*x)
%   where fb = [f1 f2] is the band of interest in cycles/sample,
%   w0 = pi*(f1 + f2) and t = tan(pi*(f2 - f1)/2).
%
%   The gain is exact: each factor (x - b) becomes
%   (1 - t*b)*(z - zb)/(t*(z + exp(j*w0))), so roots at x = 1/t map to
%   z = infinity and are dropped, and zeros at x = infinity (when there
%   are more poles than zeros) appear as zeros at z = -exp(j*w0).
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
  e = exp(j*w0);
  [z, p, k] = zpkdata(zpk(Hx), 'vector');
  [zz, kz] = mapRoots(z, w0, t);
  [pz, kp] = mapRoots(p, w0, t);
  % every x-domain root contributes (z + exp(j*w0))^(-1) for a zero and
  % (z + exp(j*w0))^(+1) for a pole; the net power becomes roots at -e
  nInf = length(p) - length(z);
  if nInf > 0
      zz = [zz; -e*ones(nInf, 1)];
  elseif nInf < 0
      pz = [pz; -e*ones(-nInf, 1)];
  end
  Hz = zpk(zz, pz, k*kz/kp, 1);
end

function [zr, c] = mapRoots(r, w0, t)
%   maps x-domain roots r to z-domain roots zr; c is the product of the
%   constants each factor (x - r) contributes to the gain
  TOL = 1e-12;
  e = exp(j*w0);
  r = r(:);
  atInf = abs(1 - t*r) < TOL; % x = 1/t maps to z = infinity
  rf = r(~atInf);
  zr = e*(1 + t*rf)./(1 - t*rf);
  c = prod((1 - t*rf)/t) * (-2*e/t)^sum(atInf);
end
