function H3= mult_zpk(H1, H2)
% MULT_ZPK(H1, H2) transforms two cascaded zpk systems to a single system
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

[z1, p1, k1] = zpkdata(H1, 'v');
[z2, p2, k2] = zpkdata(H2, 'v');

mxOrd1 = mxOrdr(H1);
mxOrd2 = mxOrdr(H2);
if (mxOrd1 >= mxOrd2)
  mx_Ordr = mxOrd1;
else
  mx_Ordr = mxOrd2;
end

z3 = [z1; z2];
[sorted, idx] = sort(-imag(z3));
z3 = z3(idx);

p3 = [p1; p2];
[sorted, idx] = sort(-imag(p3));
p3 = p3(idx);

H3 = simpl(zpk(z3, p3, k1*k2));
H3 = minreal(H3, 1e-6);
