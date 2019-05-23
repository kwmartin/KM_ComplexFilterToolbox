function [ax1, ax2] = plot_drsps(H,wp,ws,colour,lim)
%   Replace this function with plot_dam() where lim has only [y1 y2]
%   PLOT_DRSPS(H) is used to plot the stopband and passband magnitude response
%   of a discrete tranfer function H. wp is the passband freqs. in rad. ws is the
%   stop-band specificatios, colour specifies the colour of the plot. lim specifies
%   plot axis [x1 x2 y1 y2].
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
fig = figure('Position',[800 100 600 600]);
ax1 = subplot(2,1,1);
plot(s./(2*pi),dbH,colour)

if nargin == 5
    if length(lim) ~= 4
        error('The specifications for plotting must be a vector of size 4');
    end
    x1 = lim(1);
    x2 = lim(2);
    y1 = lim(3);
    y2 = lim(4);
else
	x1 = -0.5;
	x2 = 0.5;
	y1 = 1.8*min(A);
	y2 = 2;
end

N = length(s);
n1 = x2n(wp(1));
n2 = x2n(wp(2));
pbMin = min(dbH(n1:n2));

axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')
ax2 = subplot(2,1,2);
plot(s./(2*pi),dbH,colour)

wdiff = wp(2) - wp(1);
x1 = wp(1) - 0.05*wdiff;
x2 = wp(2) + 0.05*wdiff;
mxH = db(max(h));
y1 =  + pbMin - 0.1;
y2 = max(dbH) + 0.1;

axis([x1 x2 y1 y2])
title('Passband')
ylabel('dB')
xlabel('Frequency')
