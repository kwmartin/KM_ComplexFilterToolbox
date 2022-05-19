function ndB = plotFFT(xin, ylim, Fs);
%   ndB = plotFFT(xin, ylim) does an FFT on xin and plots the normalized
%   results
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

n=size(xin, 1);
y=fft(xin);
y(1) = eps;
ya=abs(y);
ymax = max(ya);
ym=ya./ymax;
ndB=20*log10(ym+eps);
dB=20*log10(ya+eps);
Ts = 1/Fs;
Tdata = Ts*n;
deltF = Fs/n;
f=-Fs/2:deltF:(Fs/2)*(1-1/n);

figure('Position',[800 100 600 600]);
% ndB(1) = ylim(1) - 20;
plot(f,[ndB((n/2 + 1):n); ndB(1:n/2)],'LineWidth',1);
axis([f(1) -f(1) ylim]);
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')

y=y(:);
ya=ya(:);
ym=ym(:);
dB=dB(:);
ndB=ndB(:);
f=f(:);
a=1;
