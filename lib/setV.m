function v = setV(x,y)
%   v = setV(x,y) uses a cubic spline to set weighting functions for
%   filtering filter-bank outputs
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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
    rng = 1:x(end);
    s = spline(x,y,rng);
    s(s < 0) = 0;
    v = zeros(256,1);
    v(128 + rng) = s;
    v(128 - rng) = s;
    %v(1) = 0;
    a_=1; % a line at the end to place a breakpoint
