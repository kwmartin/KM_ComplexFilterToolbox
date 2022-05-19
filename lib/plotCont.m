function plot_Cont(H,ylim)
%   ax1 = plot_GD(H,colour,ylim) plots the group delay of a continuous
%   system
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

    if nargin == 1
        ylim = -250;
    end
    colour = 'r';

    f = -2:1e-4:2;
    w = 2*pi*f;
    s_ = j*w;
    [lgH, phH, gdH, dLdW, dTdW] = AnlzH(H, w(:));
    figure
    dbH = real(lgH).*20./log(10);
    ax1 = plot(w,dbH,colour,'LineWidth',1);
    axis([-2 2 ylim max(dbH)+5]);
    a = 1;