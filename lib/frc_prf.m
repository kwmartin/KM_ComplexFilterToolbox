%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function H2 = frc_prf(H)
% FRC_PRF(H) is used to take a zpk TF that is almost real and to make
% all coefficients of numerator and denominator polynomials positive real
%

[n,d] = tfdata(H, 'v');
n2 = real(n);
d2 = real(d);
h = tf(n2, d2)
H2=simpl(zpk(h));
