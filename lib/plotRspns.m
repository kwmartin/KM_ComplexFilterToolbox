function [ax1 ax2, f, ym] = plotRspns(xin, wp, c, ylim);
%   plot magnitude response xin; used to superimpose responses
%   from Monte Carlo simulations
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

if nargin==2, colour=c; else, colour='m'; end
n=size(xin, 1);
y=fft(xin);
ya=abs(y)/(n/2);
ymax = max(ya);
ym=ya./ymax;
ndB=20*log10(ym+eps);
dB=20*log10(ya+eps);
f=-0.5:1/n:0.5-1/n;

ax1 = subplot(2,1,1);
plot(f,[ndB((n/2 + 1):n); ndB(1:n/2)],c);
axis([-0.5 0.5 ylim]);
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')

ax2 = subplot(2,1,2);
plot(f,[ndB((n/2 + 1):n); ndB(1:n/2)],c);
wdiff = wp(2) - wp(1);
x1 = wp(1) - 0.1*wdiff;
x2 = wp(2) + 0.1*wdiff;
y1 = -2.0;
y2 = 0.1;
axis([x1 x2 y1 y2])
title('Passband')
ylabel('dB')
xlabel('Frequency')

y=y(:);
ya=ya(:);
ym=ym(:);
dB=dB(:);
f=f(:);
