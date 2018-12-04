function [X3, elem] = rmvSCmplx(X1, lddr)
%   [X3, elem] = rmvSCmplx(X1) removes a pole at infinity, including a complex freq. independent residue
%   from either the numerator or denominator, whichever is higher order
%   It also adds the corresponding component to the lddr object
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
global imagRoots;
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

ord = fndOrdr(X1);
if ord(1) < ord(2)
  type = 'SH'
  X1 = invert_zpk(X1);
else
  type = 'SR'
end

tol = 2e-6;
[Ks Pls Rem] = findRes(X1);
if (length(Rem) ~= 2) || abs(Rem(1)) < tol
  error('Input Model is Incorrect')
end
if abs(Rem(2)) < 1e-7
  Rem(2) = 0;
end
Rem = cleanParts2(Rem);
%Rem(1) = real(Rem(1));
if real(Rem(2)) > 2e-5
    [n, d] = residue(Ks, Pls, [real(Rem(2))]);
else
    [n, d] = residue(Ks, Pls, []);
end
X2 = tf(n, d);
if type == 'SH'
  elem = ladderElem(0, Rem(1), 0, imag(Rem(2))*j, 'SHC');
  [num, den] = tfdata(X2, 'v');
  if ~isempty(num(num~=0))
    X3 = invert_zpk(X2);
  else
    X3 = tf(0, 1);
  end
else
  elem = ladderElem(Rem(1), 0, imag(Rem(2))*j, 0, 'SRL');
  X3 = X2;
end
lddr.addElem(elem);
sprintf('Condition Number: %0.5g', condition(X3))
X3 = simpl(X3, 2e-6);
