function [X5, elem1, elem2] = rmv2PolesS(X1, P1, P2, lddr)
% [X5, elem1, elem2] = rmv2PolesS(X1, P1, P2, lddr) removes two loss poles
% It uses a partial removal of a pole at infinity
% It also sets the components of a ladder object
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
warning('off', 'Control:ltiobject:ZPKComplex');

ord = fndOrdr(X1);
if ord(1) < ord(2)
  type = 'SHSR'
  X1 = invert_zpk(X1);
else
  type = 'SRSH'
end

tol = 1e-8;
if abs((P1 + P2)/(P1 - P2)) < 1e-6
    P1 = (P1 - P2)/2;
    P2 = -P1;
end
X1P1 = evalfr(X1, P1);
X1P2 = evalfr(X1, P2);
K = (X1P2 - X1P1)/(P1 - P2);
K = real(K);
X = -X1P1 - K*P1;
X = imag(X)*j;
if abs(X) < 1e-7
  X = 0
end
tf1 = tf([K, X], [1]);
%X2 = simpl(tf(X1) + tf1, tol);
X2 = tf(X1) + tf1;
X3 = invert_zpk(X2);

[X4, k1, k2] = rmv2PolesRes(X3, P1, P2, 1e-10);
%[X4, k1] = rmv_pole2(X3, P1);
%[X5, k2] = rmv_pole2(X4, P2);
if type == 'SRSH'
  [C2, y2, L2, x2] = calcLCXY(k1, k2, P1, P2);
  elem1 = ladderElem(-K, 0, -X, 0, 'SRL');
  elem2 = ladderElem(L2, C2, x2, y2, 'SHLC');
  [num, den] = tfdata(X4, 'v');
  if ~isempty(num(num~=0))
    X5 = invert_zpk(X4);
  else
    X5 = tf(0, 1);
  end
else
  X5 = X4;
  [L2, x2, C2, y2] = calcLCXY(k1, k2, P1, P2);
  elem1 = ladderElem(0, -K, 0, -X, 'SHC');
  elem2 = ladderElem(L2, C2, x2, y2, 'SRLC');
end
lddr.addElem(elem1);
lddr.addElem(elem2);
sprintf('Condition Number: %0.5g', condition(X5))
X5 = fixRes(X5);
X5 = simpl(X5, 2e-6);