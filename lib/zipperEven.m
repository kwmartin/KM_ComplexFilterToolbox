function Ev = zipperEven(poly)
%   Ev = zipperEven(poly) converts a polynomial to being complex even
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
n = length(poly);
poly = reshape(poly, [1, n]);
if (rem(n,2) == 0)
	poly(1:2:end) = imag(poly(1:2:end))*j;
	poly(2:2:end) = real(poly(2:2:end));
else
	poly(1:2:end) = real(poly(1:2:end));
	poly(2:2:end) = imag(poly(2:2:end))*j;
end
Ev = poly;
