function [K0, K1, K2, X2, fail] = rmvl3(X0, wp)
%   does a removal 3 operation
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
  warning('off', 'Control:ltiobject:TFComplex');
  posElemsOnly = true;
  tol = 10*sqrt(eps);
  fail = true;
  ord = fndOrdr(X0);
  numOrdr1 = ord(1);
  tmp0 = 1/(X0*tf([1,0],1));
  K0 = real(evalfr(tmp0, 1j*wp));
  X1 = X0 - 1/tf([K0, 0],1);
  tmp1 = minreal(X1*(tf([1, 0], 1))/tf([1, 0, wp*wp], 1), tol);
  tmp2 = prune(tmp1);
  K1 = real(evalfr(tmp2, 1j*wp));
  K2 = 1.0/(K1*wp*wp);
  tmp3 = minreal(1/X1 - tf([1/K1, 0], 1)/tf([1, 0, wp*wp], 1), tol);
  X2inv = prune(tmp3);
  X2 = 1/X2inv;
  ord = fndOrdr(X2);
  numOrdr2 = ord(1);
  if ((numOrdr2 + 2) ~= numOrdr1)
    error('Order reduction by 2 failed');
  end
  if (isfinite(K0) && isfinite(K1) && isfinite(K2) && isfinite(X2))
    fail = false;
  end
  [n, d] = tfdata(X2, 'v');
  if (~isempty(n(n < 0)))
    fail = true;
  end
  if (~isempty(d(d < 0)))
    fail = true;
  end
  if posElemsOnly
    if (K0 < 0 || K1 < 0 || K2 < 0)
      fail = true;
    end
  end
  