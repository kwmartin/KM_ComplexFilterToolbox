%function [y] = tmplt(x)
%   [y] = tmplt(x) is a template for new functions
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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
%   y = x;
%   a_=1; % a line at the end to place a breakpoint

fp = [0.015625 0.015625*2 0.015625*3 0.015625*4 0.015625*5];
wp = 2*pi*fp;
fin = fp;
k = 2*sin(wp/2);
win = 2*pi*fin;
N = length(wp);
x0 = zeros(size(wp));
x1 = -ones(size(wp));
[X10 X20] = fndInitXs(x0,x1, k);
npts = 2^14;
t = (0:(npts-1))';
%xin = sum(sin(t(:)*win),2);
xin = sum(t*win, 2);
G = 0.05;
[Xfb, Xs, Xe, Xs1, X1, X2] = simResonators2(xin, k, G, X10, X20);
figure;
plot(Xfb(:,1));
hold;
plot(Xs(:,1));

xin2 = flip(xin);
[X10 X20] = fndInitXs(Xfb(end,:),-Xs(end,:), k);
[Xfb, Xs, Xe, Xs1, X1, X2] = simResonators2(xin2, k, G, X10, X20);
figure;
plot(Xfb(:,1));
hold;
plot(Xs(:,1));
% fp = [0.015625 0.015625*2];
% [Xfb, Xs, Xe, Xs1, X1, X2] = simBckFrth(xin, fp, G);
a = 1;