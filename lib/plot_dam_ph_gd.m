function results = plot_dam_ph_gd(H,frng,ymin,colour)
%   [lgH, phH, gdH, dLdW, dTdW] = plot_dam_ph_gd(H,frng,ymin,colour) is used to plot the
%   amplitude, phase, and group delay of a digital transfer function.
%   of a discrete tranfer function H. frng is the passband freqs. in Hx.,
%   colour specifies the colour of the plot.
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
% x2n=@(x)uint64(length(w)*(x + 0.5));

x1 = frng(1);
x2 = frng(2);

f2 = x1:deltF:x2;
w = 2*pi*f2;
[lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w);
dbH = lgH.*(20/log(10));

fig = figure('Position',[800 100 400 500]);

ax1 = subplot(3,1,1);
plot(f2,dbH,colour);

y1 =  ymin;
y2 = max(dbH) + 2;

axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')

ax2 = subplot(3,1,2);
plot(f2,phH,colour);

y1 =  min(phH) - 0.5;
y2 = max(phH) + 0.5;

axis([x1 x2 y1 y2])
title('Phase')
ylabel('Radians')
xlabel('Frequency')

ax3 = subplot(3,1,3);
plot(f2,gdH,colour);

minGd = min(gdH);
maxGd = max(gdH);
y1 =  minGd - 1;
y2 = maxGd + 1;

axis([x1 x2 y1 y2])
title('Group Delay')
ylabel('Seconds')
xlabel('Frequency')

results.lgH = lgH;
results.phH = phH;
results.gdH = gdH;
results.dLdW = dLdW;
results.dTdW = dTdW;
results.f = f2;

a=1;
