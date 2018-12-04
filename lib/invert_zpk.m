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

function H2= invert_zpk(H1)
% INVERT_ZPK(H1) returns 1/H1 where H1 and H2 are zpk models
%

[z1, p1, k1] = zpkdata(H1, 'v');
if k1 ~= 0
    H2 = zpk(p1, z1, 1/k1);
else
    H2 = zpk([], [], k1);
end
