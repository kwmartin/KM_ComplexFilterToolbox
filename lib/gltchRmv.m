function outDat = gltchRmv(inDat)
%   outDat = gltchRmv(inDat) removes one sample glitches (for example in
%   group delay caused by loss poles in equiripple region
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
    diff1 = diff(inDat);
    indx1 = find(diff1 < -0.9);
    indx2 = find(diff1 > 0.9);
    if length(indx1) ~= length(indx2)
        error('gltchRmv failed')
    end
    outDat = inDat;
    for i = 1:length(indx1)
        outDat(indx1(i)+1) = (inDat(indx1(i)) + inDat(indx1(i) + 2))/2.0;
    end
    for i = 1:length(indx2)
        outDat(indx2(i)+1) = (inDat(indx2(i)) + inDat(indx2(i) + 2))/2.0;
    end

    a=1;