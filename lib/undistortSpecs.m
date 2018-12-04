function [p, px, wp, ws, as] = undistortSpecs(p, px, wp, ws, as)
%   undistorts all specification frequencies
%   All spec frequencies should be between -0.5 and 0.5
%   frequencies -0.499 and 0.499 are deleted from the specs
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
p = atan(p/2)/pi;
px = atan(px/2)/pi;
wp = atan(wp/2)/pi;

ws(1) = [];
ws(end) = [];
as(1) = [];
as(end) = [];
ws = atan(ws/2)/pi;
