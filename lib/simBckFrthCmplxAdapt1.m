function [Xfb, Xs, Xe] = simBckFrthCmplxAdapt1(xin, fp, G)
%   [Xfb, Xs, Xe] = simBckFrthCmplx(xin, fp, G) simulates
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
    N = length(wp);
    X10 = ones(size(wp));
    xinrvs = flip(xin);
    Xes = [];
    delts = [];
    u = 1/(2*N);
    onesVctr = zeros(1,N);
    for i = 1:500
        if rem(i,2) == 1
            xi = xin;
            e2jwp = exp(1j*wp);
            sgn = 1;
        else
            xi = xinrvs;
            e2jwp = exp(-1j*wp);
            sgn = -1;
        end
        [Xfb, Xs, Xe, X1o] = simCmplxResonators1(xi, e2jwp, G, X10);
        X10 = Xfb(end,:);

        xpwr = sum(Xfb.*conj(Xfb));
        xcor = sum(Xs);
        plim = 0.025*max(xpwr);
        indxs = find(xpwr > plim);
        xpwr2 = zeros(1,N);
        xpwr2(indxs) = xpwr(indxs);
        xcor2 = zeros(1,N);
        xcor2(indxs) = xcor(indxs);
        deltx = -sgn*u*(xcor2./(xpwr2 + 1e-3*onesVctr));
        delts = [delts ; deltx];
        wp = wp.*(1 + deltx);

        Xes = [Xes; Xe(end)];
        a = 1;
    end
    a=1;