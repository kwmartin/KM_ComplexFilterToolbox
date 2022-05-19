function plotRial(wp, G, minY)
% plotRial(wp, G, minY) plots the magnitude transfer function of a Rial
% filter.
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
    f = -0.5:1/8192:0.5;
    w = 2*pi*f;
    Hw = anlzRial(wp, w, G);
    figure('Position',[800 100 600 600])
    plot(f,db(Hw(:,1)));
    hold
    for i = 2:length(wp)
        plot(f,db(Hw(:,i)));
    end
    axis([-0.5 0.5 minY 2])
    a=1;
