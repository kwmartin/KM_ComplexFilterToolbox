function [Xfb, Xs, Xe, Xs1, X1, X2] = simBckFrthAdapt(xin, fp, G)
%   [Xfb, Xs, Xe, Xs1, X1, X2] = simBckFrthAdapt(xin, fp, G) simulates
%   short data segments by running forwards and backwards multiple times.
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
    wp = 2*pi*fp;
    wp = wp(:).';
    k = 2*sin(wp/2);
    N = length(wp);
    x0 = zeros(size(wp));
    x1 = -ones(size(wp));
    [X10 X20] = fndInitXs(x0,x1, k);
    xinrvs = flip(xin);
    npts = length(xin);
    delts = ones(npts,1);
    u = 1/(4*N);
    ks = [];
    delts = [];
    Xes = [];
    strd = 1:N;
    onesVctr = ones(1,N);
    for i = 1:10
        if rem(i,2) == 1
            xi = xin;
        else
            xi = xinrvs;
        end
        [Xfb, Xs, Xe, Xs1, X1, X2] = simResonators2(xi, k, G, X10, X20);
        [X10 X20] = fndInitXs(Xfb(end,:),-Xs(end,:), k);
        xpwr = sum(Xs.*Xs);
        xcor = sum(Xs1);
        plim = 0.025*max(xpwr);
        indxs = find(xpwr > plim);
        xpwr2 = zeros(1,N);
        xpwr2(indxs) = xpwr(indxs);
        xcor2 = zeros(1,N);
        xcor2(indxs) = xcor(indxs);
        deltx = -u*(xcor2./(xpwr2 + 1e-3*onesVctr));
        % delts(i) = max(abs(deltx));
        meanDlt = mean(deltx);
        dK = ones(size(k))*meanDlt;
        delts = [delts ; deltx];
        k1 = k(1)*(1 + meanDlt);
        w0 = 2*asin(k1/2);
        wp = w0.*strd;
        % k = k.*(1 + dK);
        k = 2*sin(wp/2);
        ks = [ks; k];
        Xes = [Xes; Xe(end)];

        a = 1;
    end
    figure;
    plot(ks(:,1));
    hold
    for j = 2:N
        plot(ks(:,j));
    end
    a=1;