function y = firFlt(a, xin)
%   y = firFlt(a, xin)
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
	xin = xin(:);
	Na = length(a);
	a = a(:).'; % row vector
	xs = zeros(1,Na);
	xm = zeros(1,Na);
	npts = length(xin);
	y = zeros(npts,1);
	xs(1) = xin(1);
	for i = 1:npts
		xm = a.*xs;
		y(i) = sum(xm);
		xs(2:Na) = xs(1:Na-1);
        y(i) = sum(xm);
		if i < npts
			xs(1) = xin(i+1);
		end
    end
    a = 1;
