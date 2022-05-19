function [Yt, Y1t, Y2t, Y3t, Y4t] = simEcgs(xin, fp, G)
%   [Yt] = simEcgs(xin, fp, G) simulates
%   short ecg waveforms frame by frame using good FIR filters.
%   The latency from input peaks to output peaks in Y4t is 1793 samples at Fs=256
%   which is 7.004s.
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
    wp = 2*pi*fp;
    wp = wp(:).';
    N = length(wp);
    e2jwp = exp(1j*wp);
    Xfbi = zeros(size(wp));
    xi = xin(1:N+1);
    xi = xi(:);
    Yt = [];
    Y1t = [];
    Y2t = [];
    Y3t = [];
    Y4t = [];
    zrs = zeros(N+1,1);
    v1 = zeros(N/4,1);
    v1(3:50) = 1:48;
    v1((N/4 - 48):(N/4 - 1)) = 48:-1:1;
    % [Xfb, Xs, Xe, Y, Yp] = simCmplxResonators2(xi, e2jwp, G, Xfbi);
    % Xfbi = Xfb(end,:);
    xi = zeros(N+1,1);
    nmbFrms = fix(length(xin)/N);
    for i = 1:nmbFrms
        n2 = (i-1)*N+N+1;
        if n2 > length(xin)
            n2 = n2 - 1;
            xi(1:end-1) = xin((i-1)*N+1:n2);
            xi(end) = 0; % corrects last frame as we can't overlap
        else
            xi = xin((i-1)*N+1:n2);
        end
        xi = xi(:);
        %  tic
        [Xfb, Xs, Xe, Y, Yp] = simCmplxResonators2(xi, e2jwp, G, Xfbi);
        % toc
        Y(:,1) = zrs;
        Y(:,2) = zrs;
        Y(:,end) = zrs;
        Y(:,241) = zrs; % This is 60Hz
        Xfbi = Xfb(end,:);
        y0 = real(sum(Y(:,:),2));

        Yt = [Yt; y0(1:end-1)];
        Y1t = [Y1t; Y(1:end-1,:)];

        a = 1;
    end
    Y2t = Y1t*v1;
    y3 = Y2t.*conj(Y2t);
    Y3t = y3./std(y3);
    cscdLP = dsgnLpFltr(5,0.025);
    Y4t = cscdLP.sim(Y3t, 0);
    % Y4t = real(lpFltr(Y3t,0.025));
    Yt(1:1792) = [];
    Y1t(1:1792,:) = [];
    Y2t(1:1792) = [];
    Y3t(1:1792) = [];
    Y4t(1:1792) = [];
    a=1;