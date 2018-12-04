function [X5, elem1, elem2] = rmvUsingX2(X1, P, lddr)
%   [X5, elem1, elem2] = rmvUsingX2(X1, P, lddr) removes loss pole P from X1,
%   adds the corresponding components to the lddr object, returns the remaining
%   transfer function, and the components
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
warning('off', 'Control:ltiobject:ZPySComplex');

ord = fndOrdr(X1);
if ord(1) < ord(2)
  type = 'SHSR'
  X1 = invert_zpk(X1);
else
  type = 'SRSH'
end

tol = 2e-6;
X1P = evalfr(X1, P);
X = -X1P;
X = imag(X)*j;
X2 = simpl(tf(X1)  + X, 2e-6);
X3 = invert_zpk(X2);
[X4, k] = rmv_pole2(X3, P);

if type == 'SRSH'
  L2 = 1/k;
  x2 = -P/k;
  if abs(x2) < 1e-6 x2 = 0; end
  elem1 = ladderElem(0, 0, -X, 0, 'SRX');
  elem2 = ladderElem(L2, 0, x2, 0, 'SHL');
  X4 = simpl(X4, tol);
  [num, den] = tfdata(X4, 'v');
  if ~isempty(num(num~=0))
    X5 = invert_zpk(X4);
  else
    X5 = tf(0, 1);
  end
else
  C2 = 1/k;
  y2 = -P/k;
  elem1 = ladderElem(0, 0, 0, -X, 'SHY');
  elem2 = ladderElem(0, C2, 0, y2, 'SRC');
  X5 = simpl(X4, tol);
end
lddr.addElem(elem1);
lddr.addElem(elem2);
X5 = fixRes(X5);
X5 = simpl(X5, 2e-6);
sprintf('Condition Number: %0.5g', condition(X5))