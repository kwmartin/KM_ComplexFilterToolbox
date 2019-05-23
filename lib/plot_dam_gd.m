function [ax1, ax2] = plot_dam_gd(H,wp,ws,colour)
%   PLOT_DRSPS(H) is used to plot the stopband and passband magnitude response
%   of a discrete tranfer function H. wp is the passband freqs. in rad. ws is the
%   stop-band specificatios, colour specifies the colour of the plot.
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

[zd pd kd] = zpkdata(H);
b = poly(zd{1});
a = poly(pd{1});
A = db(kd.*freqz(b,a,2*pi*[wp ws]));
w = -0.5:1e-4: 0.5;
s = 2*pi*w;
x2n=@(x)int16(length(w)*(x + 0.5));
h=kd.*freqz(b,a,s);
dbH = db(h);
phH = unwrap(angle(h));
fig = figure('Position',[800 100 600 600]);
ax1 = subplot(2,1,1);
plot(w,dbH,colour)

x1 = -0.5;
x2 = 0.5;

N = length(s);

wdiff = wp(2) - wp(1);
x1 = wp(1) - 0.25*wdiff;
x2 = wp(2) + 0.25*wdiff;
n1 = x2n(x1);
n2 = x2n(x2);
y1 =  min(dbH(n1:n2)) - 0.1;
y2 = max(dbH(n1:n2)) + 0.1;

axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')
ax2 = subplot(2,1,2);

grpDelay = -diff(phH(n1:n2+1))*1e4/(2*pi);
plot(w(n1:n2),grpDelay,colour)

minGd = min(grpDelay);
maxGd = max(grpDelay);
y1 =  minGd - 2;
y2 = maxGd + 2;

axis([x1 x2 y1 y2])
title('Group Delay')
ylabel('Seconds')
xlabel('Frequency')
a=1;
