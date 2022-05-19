function gd = hxPlot(hx)
%   gd = hxPlot(hx) is a utility function to allow viewing the transformed group delay
%   hx is a cell array of the transformed group delay residues
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

    wx = (0:5e-4:100);
    sx = j*wx;
    N = length(hx);
    gd = 0;
    for i = 1:N
        gd = gd + rsps(hx{i},sx);
    end
    gd = real(gd);
    figure;
    plot(wx,gd);

    a=1;
