function dB = plotRspnsd(xin, ylim, nrml);
%   plot magnitude response xin assuming xin is from digital filter
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

if nargin < 3
    nrml = true
end
xin = xin(:);
n=size(xin, 1);
y=fft(xin);
ya=abs(y);
ymax = max(ya);
ym=ya./ymax;
ndB=20*log10(ym+eps);
if nrml == true
    dB=20*log10(ym+eps);
else
    dB=20*log10(ya+eps);
end
f=-0.5:1/n:0.5-1/n;
figure('Position',[800 100 600 600]);
plot(f,[dB((n/2 + 1):n); dB(1:n/2)],'LineWidth',1);
axis([-0.5 0.5 ylim]);
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')

y=y(:);
ya=ya(:);
ym=ym(:);
dB=dB(:);
f=f(:);
a=1;
