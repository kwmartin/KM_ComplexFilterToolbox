function [X6, elem1, elem2] = rmv2PolesS2(X1, P1, P2)
% [X6, elem1, elem2] = rmv2PolesS2(X1, P1, P2) removes two loss poles
%   using a partial removal of a pole at infinity. It returns the remaining
%   reactance function and the two branches
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
if abs((P1 + P2)/(P1 - P2)) < 1e-5
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

[z3, p3, k3] = zpkdata(X3, 'v');
k1 = k3;
p4 = p3(find(abs(p3 - P1) > abs(P1)*2e-4));
if (length(p4) + 1) ~= length(p3)
    error('After removal order is incorrect');
end
X1_ = zpk(z3, p4, k3);
k_1 = evalfr(X1_, P1);
p5 = p3(find(abs(p3 - P2) > abs(P2)*2e-4));
if (length(p5) + 1) ~= length(p3)
    error('After removal order is incorrect');
end
X2_ = zpk(z3, p5, k3);
k_2 = evalfr(X2_, P2);
if abs(k_1 - k_2)/(k_1 + k_2) < 2e-7
    k_1 = (k_1 + k_2)/2;
    k_2 = k_1;
end
ply1 = poly(z3);
p6 = p4(find(abs(p4 - P2) > abs(P2)*2e-4));
if (length(p6) + 1) ~= length(p4)
    error('After removal order is incorrect');
end
ply3 = poly(p6);
ply1(find(abs(ply1) < 1e-5)) = 0;
ply3(find(abs(ply3) < 1e-5)) = 0;
s = tf('s');
k3N3 = (k1*tf(ply1, [1]) - (k_1*(s - P2) + k_2*(s - P1))*tf(ply3, [1]))/ ...
((s - P1)*(s - P2));
k3N3 = simpl(k3N3, 5e-6);
den3 = tf(ply3, [1]);
X5 = simpl(k3N3/den3, 1e-5);

%[X4, k1] = rmv_pole2(X3, P1);
%[X5_, k2] = rmv_pole2(X4, P2);
%[X5__, k2] = rmv_pole2(X3, P2);

if type == 'SRSH'
  [C2, y2, L2, x2] = calcLCXY(k_1, k_2, P1, P2);
  elem1 = ladderElem(-K, 0, -X, 0, 'SRL');
  elem2 = ladderElem(L2, C2, x2, y2, 'SHLC');
  [num, den] = tfdata(X5, 'v');
  if ~isempty(num(num~=0))
    X6 = invert_zpk(X5);
  else
    X6 = tf(0, 1);
  end
else
  X6 = X5;
  [L2, x2, C2, y2] = calcLCXY(k_1, k_2, P1, P2);
  elem1 = ladderElem(0, -K, 0, -X, 'SHC');
  elem2 = ladderElem(L2, C2, x2, y2, 'SRLC');
end
X6 = simpl(X6, 2e-6);
sprintf('Condition Number: %0.5g', condition(X6))