function [Xfb, Xs, Xe, Xs1, X1, X2] = simBckFrth(xin, fp, G)
%   [Xfb, Xs, Xe, Xs1, X1, X2] = simBckFrth(xin, fp, G) simulates
%   short data segments by running forwards and backwards multiple times.
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
    wp = 2*pi*fp;
    wp = wp(:).';
    k = 2*sin(wp/2);
    N = length(wp);
    x0 = zeros(size(wp));
    x1 = -ones(size(wp));
    [X10 X20] = fndInitXs(x0,x1, k);
    xinrvs = flip(xin);
    Xes = [];
    for i = 1:100
        if rem(i,2) == 1
            xi = xin;
        else
            xi = xinrvs;
        end
        [Xfb, Xs, Xe, Xs1, X1, X2] = simResonators2(xi, k, G, X10, X20);
        [X10 X20] = fndInitXs(Xfb(end,:),-Xs(end,:), k);
        Xes = [Xes; Xe(end)];
        a = 1;
    end
    a=1;