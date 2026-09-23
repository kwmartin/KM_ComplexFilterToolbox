function [K0, K1, K2, X5, fail] = rmvl4(X0, wp)
%   does a removal 4 operations
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
  tol = 1e-6;
  fail = true;
  % wp must be positive for the abs(p2)-vs-wp pole match below (poles come
  % in conjugate pairs, so abs(p2) is always >= 0); every other use of wp
  % in this function is either wp*wp (sign-invariant) or of the form
  % real(evalfr(X, wp*j)/(wp*j)), which is also sign-invariant for a
  % real-coefficient X (flipping wp*j to -wp*j conjugates numerator and
  % denominator identically). So normalizing the sign here is safe for
  % callers that already pass a positive wp, and fixes callers (e.g.
  % doRmvls, via wps = imag(P(2))) that can pass a negative one.
  wp = abs(wp);
  ord = fndOrdr(X0);
  numOrdr1 = ord(1);
  K0 = real(evalfr(X0, wp*j)/(wp*j));
  X1 = simpl(tf(X0) - tf([K0, 0],1), tol);
  X2 = invert_zpk(X1);
  [z2 p2 k2] = zpkdata(X2, 'v');
  p3 = p2(find(abs((abs(p2) - wp)) > tol));
  X3 = zpk(z2, p3, k2);
  k1 = real(evalfr(X3, wp*j)/(wp*j));
  K1 = 1/k1;
  K2 = 1.0/(K1*wp*wp);
  k4 = k2 - k1;

  n2 = poly(z2);
  ply4 = poly(p3);
  den4 = tf(ply4, [1]);
  % Combine directly over the shared denominator [1 0 wp*wp]: computing
  % tf2 and tf3 separately and subtracting (as before) does not cancel
  % that common factor, needlessly squaring the denominator degree.
  num4 = tf(k2*n2 - k1*[ply4 0], [1 0 wp*wp]);
  X3raw = num4/den4;
  % The K1/K2 extraction above is constructed so that X3raw has an exact
  % pole/zero pair at +-wp (the resonance just removed) that must cancel
  % for the order to drop by 2, but simpl() alone does not perform any
  % pole/zero cancellation (its minreal call is disabled) -- so do that
  % cancellation explicitly first. Converting to zpk via zpkdata before
  % calling minreal matters: minreal on the tf-typed ratio directly does
  % not reduce complex-coefficient systems correctly.
  [zX, pX, kX] = zpkdata(X3raw, 'v');
  X4 = simpl(minreal(zpk(zX, pX, kX), tol));

  %tf1 = tf([k1 0], [1, 0, wp*wp]);
  %X4 = zpk(z2, p3, k4);
  %X4 = simpl(tf(X2) - tf1, tol);
  %tmp2 = simpl(X1*(tf([1, 0], 1))/tf([1, 0, wp*wp], 1), tol);
  %K1 = real(evalfr(tmp2, 1j*wp));
  %K2 = 1.0/(K1*wp*wp);
  %X2inv = simpl2(tf(X2) - tf([1/K1, 0], 1)/tf([1, 0, wp*wp], 1), tol);
  % check if numerator is 0
  [num, den] = tfdata(X4, 'v');
  if isempty(num(num~=0))
    X5 = tf(0, 1);
    fail = false;
    return
  else
    X5 = invert_zpk(X4);
  end
  ord = fndOrdr(X5);
  numOrdr2 = ord(1);
  if ((numOrdr2 + 2) ~= numOrdr1)
    error('Order reduction by 2 failed');
  end
  if (isfinite(K0) && isfinite(K1) && isfinite(K2) && isfinite(X2))
    fail = false;
  end
  [n, d] = tfdata(X5, 'v');
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
  