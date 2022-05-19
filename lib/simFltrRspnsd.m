function Xfb = simFltrRspnsd(fltrAnal,N,ylim)
%   Hw = simFltrRspnsd(fltrAnal,N,ylim)
%   simulates a resonator-in-a-loop filter for its impulse response,
%   analyzes the output using an FFT, and the plots the magnitude in dB
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

    tic
    % I = [0:N-1] + 0.5;
    I = [0:N-1];
    f0 = 1/N;
    fp = I*f0;
    wp = 2*pi*fp;
    f = -0.5:1e-4:0.5;
    w = 2*pi*f;
    G = 1/(1*length(wp));
    xin = zeros(8192,1);
    xin(1) = 1;
    e2jwp = exp(1j*wp);
    x0 = zeros(1,N);
    [Xfb, Xs, Xe, Y, Xp] = fltrAnal(xin, e2jwp, G, x0);
    toc
    figure;
    plotRspnsd(Y(:,1), ylim);
    hold
    for i=2:N/4
        plotRspnsd(Y(:,i), ylim);
    end

    Y2 = sum(Y,2);
    figure
    plotRspnsd(Y2, [-0.1 0.1]);
    a = 1;
