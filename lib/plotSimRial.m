function [Xfb, Xs] = plotSimRial(wp, G, minY)
% plotSimRial(cscdFltr, wp, ws, minY, color) simulates a Rial filter
% and then plots the output.
% minY is minimum for plotting; wp is is the pole frequencies
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
    xin = zeros(8192,1);
    xin(1) = 1;
    k = 2.*sin(wp./2);
    [Xfb, Xs] = simResonators(xin, k, G);
    ax1 = figure('Position',[800 100 600 600]);
    plotRspnsd(Xfb(:,1), [minY, 2]);
    hold
    N = length(wp);
    for i = 2:N
        plotRspnsd(Xfb(:,i), [minY, 2]);
    end
    a=1;
