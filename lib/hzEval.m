function gd = hzPlot(hz)
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

    f_ = -0.5:1e-4:0.5;;
    w_ = 2*pi*f_;
    s_ = j*w_;
    N = length(hz);
    gd = 0;
    for i = 1:N
        gd = gd + rspsd(hz{i},s_);
    end

    a=1;
