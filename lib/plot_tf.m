function hndl = plot_tf(H,wp,colour,lim)
%   plots a transfer function from 0.8 wp(1) to 1.2 wp(2)
%   between min db and max db
%   of a discrete tranfer function H. w is a vector containing in order: lower
%   passband frequency, upper passband frequency, lower stopband frequency,
%   and upper stopband frequency.
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
[zd pd kd] = zpkdata(H);
b = poly(zd{1});
a = poly(pd{1});
wpExtend = 0.2*max(abs(wp));
strt = wp(1) - wpExtend;
stp = wp(2) + wpExtend;
delta = (stp - strt)*1e-4;
s = strt:delta:stp;
h = 20*log_rsps(H,j*s);
hndl = figure('Position',[800 100 500 600]);
plot(s, h, colour)
axis(lim);
title('Magnitude Gain')
ylabel('dB')
