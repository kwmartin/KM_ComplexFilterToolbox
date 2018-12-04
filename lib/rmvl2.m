function [K0, X1, fail] = rmvl2(X0)
%   [K0, X1, fail] = rmvl2(X0) does a removal 2 operation
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
  tol = 2e-5;
  largeFreq = 1e20;
  fail = true;
  tmp1 = minreal(X0/tf([1,0],1));
  tmp2 = evalfr(tmp1, 1j*largeFreq);
  K0 = real(tmp2);
  X1 = simpl2(tf(X0) - tf([K0, 0],1), tol);
  if (isfinite(K0) && isfinite(X1))
    fail = false;
  end
  % check for negative coefficients
  [n, d] = tfdata(X1, 'v');
  if (~isempty(n(n < 0)))
    fail = true;
  end
  if (~isempty(d(d < 0)))
    fail = true;
  end
  if posElemsOnly
    if (K0 < 0)
      fail = true;
    end
  end
