function [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, scaleFctr)
%   [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, scaleFctr) scales specs
%   specifications are scaled proportional to scaleFctr
%   scaleFctr > 1 moves specifications further from dc
%   currently used to allow desiging with passbands = +-1
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

p = p*scaleFctr;
px = px*scaleFctr;
wp = wp*scaleFctr;
ws = ws*scaleFctr;
