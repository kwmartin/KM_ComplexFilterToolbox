function Y = setY2(gdH, T1, T2)
%   Y = setY2(gdH) sets up the Y vector
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

	gdH = gdH(:);
	N = length(gdH);
	Y = zeros(N+1,1);
	for i =1:N
		if rem(i,2) == 1
			Y(i) = gdH(i) - T1;
		else
			Y(i) = gdH(i) - T2;
        end
	end

    a = 1;