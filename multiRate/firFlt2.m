function y = firFlt2(a, xin)
%   y = firFlt2(a, xin)
%   filters xin using coefficients a and returns by
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
	xin = xin(:); % column
	Na = length(a);
	a = a(:).'; % row vector
	npts = length(xin);
	y = zeros(npts,1);
	for i = 1:npts
		y(i) = 0;
		for k = 1:Na
			if i - k < 0
				break
			else
				y(i) = y(i) + a(k)*xin(i - k + 1)
			end
		end
        bk = 1;
    end
    bk = 1;
