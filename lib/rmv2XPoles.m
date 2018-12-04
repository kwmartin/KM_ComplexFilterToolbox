function [X5, elem1, elem2, elem3] = rmv2XPoles(X1, P1, P2, lddr)
%   [X5, elem1, elem2, elem3] = rmv2XPoles(X1, P1, P2, lddr) removes two loss poles
%   from X1. The poles to be removed are P1 and P2, the corresponding elements
%   are stored in the lddr object. They are also returned in elem1, elem2, and
%   elem3. The remaining transfer function is returned in X5. A partial removal of
%   a reactance and pole at infinity is used for the first branch. The loss branches
%   are either series capacitor in parallel with a complex susceptance
%   or shunt inductor in series with a complex reactance
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
  elem1 = ladderElem(-K, 0, -X, 0, 'SRL');
  elem2 = ladderElem(1/k1, 0, -P1/k1, 0, 'SHL');
  elem3 = ladderElem(1/k2, 0, -P2/k2, 0, 'SHL');
  [num, den] = tfdata(X4, 'v');
  if ~isempty(num(num~=0))
    X5 = invert_zpk(X4);
  else
    X5 = tf(0, 1);
  end
else
  X5 = X4;
  elem1 = ladderElem(0, -K, 0, -X, 'SHC');
  elem2 = ladderElem(0, 1/k1, 0, -P1/k1, 'SRC');
  elem3 = ladderElem(0, 1/k2, 0, -P2/k2, 'SRC');
end
lddr.addElem(elem1);
lddr.addElem(elem2);
lddr.addElem(elem3);
sprintf('Condition Number: %0.5g', condition(X5))
X5 = fixRes(X5);
X5 = simpl(X5, 2e-6);