function zrcss = zrCrss(x,y)
%   zrcss = zrCrss(x,y) finds the positive zero-crossings of a vector y assuming y
%   is a function of x. It returns the values of x with improved accuracy
%   using interpolation
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

    indx = find(y(1:end-1) <= 0 & y(2:end) > 0);
    deltY = y(indx+1) - y(indx);
    deltX = x(indx+1) - x(indx);
    m = deltY./deltX;
    zrcss = x(indx+1) - y(indx+1)./m;

    a = 1;
