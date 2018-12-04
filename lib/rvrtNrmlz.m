function [H2,lddr2] = rvrtNrmlz(H1, lddr1, sclFctr, shftFctr)
% [H2,lddr2] = rvrtNrmlz(H1, lddr1, scaleFctr, shftFctr) denormalizes
% ladder and transfer function; scaleFctr and shftFctr were used for
% normalization
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

lddr2 = ladderClass(lddr1);
lddr2.scale(1/sclFctr)
lddr2.freqShft(-shftFctr*2*pi);
H2 = freqScale(H1, 1/sclFctr);
H2 = freq_shift(H2, -shftFctr*2*pi);
