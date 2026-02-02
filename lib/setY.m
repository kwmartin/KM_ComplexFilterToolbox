function Y = setY(gdH, DT, GD1, GD2)
%   Y = setY(gdH) sets up the Y vector
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

    Np = fix((length(gdH) + 1)/2);
    Nc = fix(Np/2);
    Y = zeros(2*Nc, 1);
    for i = 1:Nc
        Y(2*i - 1) = GD1 - gdH(2*i - 1);
        Y(2*i) = GD2 - gdH(2*i);
    end

    a = 1;