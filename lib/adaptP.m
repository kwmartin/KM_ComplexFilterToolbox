function H = adaptP(H)
%   [H2, deltT] = adaptP(H) adapts the poles of a digital filter to correct the group delay
%   to be equiripple after being distorted by the bilinear transform
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
    dp2rq = @(dp) [real(dp(:)); imag(dp(:))];
    deltW = 1e-5*2*pi;
    updK = -0.02;
    
    [z, p, k] = sortZPK(H);
    a = angle(p);
    m = abs(p);
    %m = ones(size(m))*m(end);
    m = sqrt(m); % increase Q to ensure we start with enough peaks
    a1 = tan(1.00*a);
    % a1 = a;
    p1 = m.*exp(j*a1);
    H1 = zpk(z, p1, k);
    w1 = angle(p1);
    wrng = 1.2*[w1(1) w1(end)];
    w = wrng(1):deltW:wrng(2);
    Np = length(p1);
    wz = fndZeroCrs(H1);
    Tz = p2T(H1, wz);
    %dT = mean(abs(diff(gdHz1(1:Np))));

    p = p1;
    gd1 = Tz(Np);
    %gd2 = gd1 - 0.25;
    gd2 = gd1 - gd1/200;;
    figure;
    hold on
    f = w./(2*pi);
    for i = 1:50
        H = zpk(z, p, k, 1);
        wz = fndZeroCrs(H);
        Tz = p2T(H, wz);
        Y = setY2(Tz, gd1, gd2);
        sens = plSens(p, wz);
        dX = sens\Y;
        dP = rq2dp(dX);
        p = p - 0.25*dP;
        T = p2T(H, w);
        plot(f,T)
    end
    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w(:));

    a = 1;


