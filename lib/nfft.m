function [f, ndB, dB, ym, ya] = nfft(xin,c);
%   plot the FFT of xin normalized to its maximum value
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
n=max(size(xin));
y=fft(xin);
ya=abs(y)/(n/2);
ym=ya./max(ya);
ndB=20*log10(ym+eps);
dB=20*log10(ya+eps);
f=0:1/n:1.0-1/n;
plot(f,[ndB(n/2 + 1:n); ndB(1:n/2)],colour);
axis([-0.5 0.5 -160 0]);
y=y(:);
ya=ya(:);
dB=dB(:);
f=f(:);
