function [Xfb, Xs, Xe, Y, Xp] = simBckFrthCmplx(xin, fp, G)
%   [Xfb, Xs, Xe] = simBckFrthCmplx(xin, fp, G) simulates
%   short data segments by running forwards and backwards multiple times.
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
    Xfbi = zeros(size(wp));
    xinrvs = flip(xin);
    Xes = [];
    for i = 1:1000
        if rem(i,2) == 1
            xi = xin;
            e2jwp = exp(1j*wp);
            % X10 = conj(Xfb_end);
        else
            xi = xinrvs;
            e2jwp = exp(-1j*wp);
            % X10 = conj(Xfb_end);
        end
        tic
        [Xfb, Xs, Xe, Y, Xp] = simCmplxResonators2(xi, e2jwp, G, Xfbi);
        toc
        % tic
        % [Xfb, Xs, Xe, Y, Xp] = simCmplxResonators3(xi, e2jwp, G, Xfbi);
        % toc
        % tic
        % [Xfb, Xs, Xe, Y, Xp] = simCmplxResonators4(xi, e2jwp, G, Xfbi);
        % toc
        Xfb_end = Xfb(end,:);
        %X10 = fndInitXfb1(Xfb_end,xi(end));
        Xfbi = fndInitXfb2(Xfb,xi,size(Xfb,2));
        Xes = [Xes; Xe(end)];
        a = 1;
    end
    a=1;