function H2 = scaleZPK(H, sclFctr)
%   scale a zpk system up or down in frequency
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
srt = @(p) sort(p, 'ComparisonMethod', 'real');
[z, p, k] = zpkdata(H, 'vector');
z2 = srt(z)*sclFctr;
p2 = srt(p)*sclFctr;
k2 = k*(sclFctr^(length(p) - length(z)));
H2 = zpk(z2, p2, k2, H.Ts);
