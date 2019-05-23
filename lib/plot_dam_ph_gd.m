function [ax1, ax2] = plot_dam_ph_gd(H,wp,ws,colour)
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

deltF = 1e-5;
w = -0.5:deltF: 0.5;
x2n=@(x)int32(length(w)*(x + 0.5));

wdiff = wp(2) - wp(1);
x1 = wp(1) - 0.25*wdiff;
x2 = wp(2) + 0.25*wdiff;
n1 = x2n(x1);
n2 = x2n(x2);

w2 = x1:deltF:x2+deltF;
s = 2*pi*w2;
[lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, s);
dbH = lgH.*(20/log(10));

fig = figure('Position',[800 100 600 1000]);

ax1 = subplot(3,1,1);
plot(w2,dbH,colour);

y1 =  min(dbH) - 0;
y2 = max(dbH) + 2;

axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')

ax2 = subplot(3,1,2);
plot(w2,phH,colour);

y1 =  min(phH) - 0.5;
y2 = max(phH) + 0.5;

axis([x1 x2 y1 y2])
title('Phase')
ylabel('Radians')
xlabel('Frequency')

ax3 = subplot(3,1,3);
plot(w2,gdH,colour);

minGd = min(gdH);
maxGd = max(gdH);
y1 =  minGd - 1;
y2 = maxGd + 1;

axis([x1 x2 y1 y2])
title('Group Delay')
ylabel('Seconds')
xlabel('Frequency')

a=1;
