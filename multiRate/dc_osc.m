function xout = dc_osc(a)
%   y = y = dc_osc(a)
%   sim of of noise in dc osc
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
    N = 2048;
    xin = zeros(N, 1);
    xout = zeros(N, 1);
    xin(1) = 1;
    xs = 0;
	for i = 1:N
        xout(i) = xin(i) + xs;
        xi = xs + a*(xout(i) - xs) + xout(i);
        xs = xi;
        aa = 0;
    end
    aa=0;
