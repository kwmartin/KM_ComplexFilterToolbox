function plotDig(H,ylim,c)
%   ax1 = plotDig(H,ylim,c) plots the response of a discrete-time
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
    if nargin == 3
        colour = c
    else
        colour = 'r';
    end
    f = -0.5:1e-6:0.5;
    w = 2*pi*f;
    s_ = j*w;
    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w(:));
    % figure
    dbH = real(lgH).*20./log(10);
    ax1 = plot(f,dbH,colour,'LineWidth',1);
    axis([-0.5 0.5 ylim 10]);
    a = 1;