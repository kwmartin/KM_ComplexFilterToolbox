function [deltT deriv] = fnd_gd_ripple(H,wp)
%   delT = fnd_gd_ripple(H,wp) finds the peak-peak ripple between wp(1) and wp(2) of H
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
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

npts = 10000;
wdiff = wp(2) - wp(1);
deltF = wdiff/(npts - 1);
w = wp(1):deltF:wp(2);

[lgH, phH, gdH, dLdW, dTdW] = AnlzH(H, w);
[gd1 i1] = min(gdH);
[gd2 i2] = max(gdH);
deltT = gd2 - gd1;
deriv = max(abs([dTdW(i1) dTdW(i2)]));
a=1;
