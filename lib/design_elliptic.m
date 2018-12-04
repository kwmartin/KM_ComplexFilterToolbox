% Early script for doing design; not currently relevant 11/2018
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
clear all;
p=[-1 -0.1 1.75]; % initial guess at finite loss poles; note pole at zero
ni=2; % number of loss poles at infinity
w1 = 0.25; % lower passband edge
w2 = 1.25; % upper passband edge
w3 = 0.0; % lower stopband edge
w4 = 1.5; % upper stopband edge
Au = 50; % upper stopband spec in dB
Al = 50; % lower stopband spec in dB
Ap = 0.01; % the passband ripple in dB

H = design_elliptic(p,ni,[w1 w2 w3 w4],[Al Au Ap]);

A = 20*log_rsps(H,j*[w3 w4]);
sprintf('Lower Stopband Spec: %4.2fdB, Actual Attenuation: %4.2fdB',Al,A(1))
sprintf('Upper Stopband Spec: %4.2fdB, Actual Attenuation: %4.2fdB',Al,A(2))
w1=-2:1e-3:2;
A1 = 20*log_rsps(H,j*w1);
w2=0.24:1e-3:1.26;
A2 = 20*log_rsps(H,j*w2);
subplot(2,1,1)
plot(w1,A1)
axis([-2 2 -60 1])
title('Stopband')
ylabel('dB')
xlabel('Frequency')
subplot(2,1,2)
plot(w2,A2)
axis([0.2 1.3 -0.05 0.005])
title('Passband')
ylabel('dB')
xlabel('Frequency')
