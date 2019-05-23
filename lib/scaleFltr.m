function H2 = scaleFltr(H, sclFctr)
%   scale a system up or down in frequency by first converting the filter
%   which must be a tf or zpk system object, to a state-space object, then
%   scaling the A, and B matrices, and then converting back to a zpk object
%   an equivalent function based on scaling the zpk poles and zeros is freqScale()
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
[a, b, c, d] = ssdata(H);
A = sclFctr*a;
B = sclFctr*b;
warning('off','Control:transformation:StateSpaceScaling')
H1 = ss(A, B, c, d);
H2 = zpk(H1);
warning('on','Control:transformation:StateSpaceScaling')
