function [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, shiftFctr)
%   shift specifications by shiftFctr; allows specifications to be given relative
%   to dc, and then shifted to any desired frequency. Negative frequency
%   specifications may be different than positive frequency
%   specifications. p is moveable poles, px is fixed poles, wp is pass-band
%   frequencies in rad. ws is stop-band edge frequencies in rad. The returned
%   [p, px, wp, ws] are shifted values
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

p = p + shiftFctr;
px = px + shiftFctr;
wp = wp + shiftFctr;
ws = ws + shiftFctr;
