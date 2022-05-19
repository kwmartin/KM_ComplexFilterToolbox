function [f ndB] = nFFT(xin, Fs);
%   [f ndB] = nFFT(xin, Fs) calculates a normalized FFT and returns f and the results from
%   -Fs/2 to Fs/
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
if rem(n,2) == 1
    xin(1) = [];
    n = n-1;
end
y=fft(xin);
y(1) = eps;
ya=abs(y);
ymax = max(ya);
ym=ya./ymax;
ndB1=20*log10(ym+eps);
Ts = 1/Fs;
Tdata = Ts*n;
deltF = Fs/n;
f=-Fs/2:deltF:(Fs/2)*(1-1/n);
ndB = [ndB1((n/2 + 1):n); ndB1(1:n/2)];
ndB=ndB(:);
f=f(:);
a=1;
