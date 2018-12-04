function [p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as)
% Predistort all specification frequencies before using bilinear transform
% All spec frequencies should be between -0.5 and 0.5
% frequencies -0.499 and 0.499 are added to the specs
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

p = 2*tan(pi*p);
px = 2*tan(pi*px);
wp = 2*tan(pi*wp);

indice = (ws ~= 0.5);
ws = ws(indice);
as = as(indice);
ws = [-0.499 ws 0.499];
as = [as(1) as as(length(as))];
ws = 2*tan(pi*ws);
