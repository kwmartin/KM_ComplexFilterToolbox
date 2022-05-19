function H2 = adaptP(H, DT)
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
    a1 = tan(1.03*a);
    p1 = m.*exp(j*a1);
    H1 = zpk(z, p1, k);
    w1 = angle(p1);
    wrng = 1.1*[w1(1) w1(end)];
    w = wrng(1):deltW:wrng(2);
    Np = length(p1);
    dT = mean(abs(diff(gdHz1(1:Np))));

    p = p1;
    gd1 = gdHz1(Np);
    gd2 = gd1 - 0.25;
    figure;
    hold on

    for i = 1:10
        H = zpk(z, p, k);
        wz = fndZeroCrs(H);
        Tz = p2T(H, wz);
        Y = setY2(Tz, gd1, gd2);
        sens = pSens3(p, wz);
        dX = sens\Y;
        dP = rq2dp(dX);
        p = p - dP;
        T = p2T(z, p, k, w);
        plot(w,T)
    end
    figure;
    plot(w,T);

    Y1 = setY2(gdHz1, gd1, gd2);
    sens1 = pSens3(p1, wz1);
    dX = sens1\Y1;
    dP = rq2dp(dX);
    p2 = p1 - dP;
    figure;
    T1 = p2T(z, p1, k, w);
    plot(w, T1);
    hold on
    T2 = p2T(z, p2, k, w);
    plot(w, T2);

    sens1 = pSens(p1, wz1);
    SMtrx1 = pSens2(p1, wz1);
    Np = length(p1);
    Nc = fix(Np/2);
    Y1 = setY(gdHz1, T1, T2);
    %X = [real(p1(1:Nc)); imag(p1(1:Nc))];
    X1 = setX(p1);
    %SMtrx1 = dTdP(sens);
    Sinv1 = inv(SMtrx1 + Pmin);

    p_1 = p1;
    p_1(1) = real(p1(1)) + j*imag(p1(1))*(1 + 1e-6);
    p_1(11) = real(p1(11)) + j*imag(p1(11))*(1 + 1e-6);
    H_1 = zpk(z, p_1, k);
    wz_1 = fndZeroCrs(H_1);
    [lgHz_1, phHz_1, gdHz_1, dLdWz_1, dTdWz_1] = AnlzDH(H_1, wz_1);
    
    SMtrx_1 = pSens2(p_1, wz_1);

    Y1 = setY(gdHz1, T1, T2);
    dX = (SMtrx1 + Pmin)\Y1; % Calculate the changes in the pole frequencies
    X2 = X1 - updK*dX;
    p2 = updP2(p1, X2);
    H2 = zpk(z, p2, k);
    [lgH2, phH2, gdH2, dLdW2, dTdW2] = AnlzDH(H2, w);
    wz2 = fndZeroCrs(H2);
    SMtrx2 = pSens2(p2, wz2);
    [lgHz2, phHz2, gdHz2, dLdWz2, dTdWz2] = AnlzDH(H2, wz2);
    Y2 = setY(gdHz2, T1, T2);
    dX = (SMtrx2 + Pmin)\Y2; % Calculate the changes in the pole frequencies
    X3 = X2 - updK*dX;
    p3 = updP2(p2, X3);
    H3 = zpk(z, p3, k);
    [lgH3, phH3, gdH3, dLdW3, dTdW3] = AnlzDH(H3, w);
    figure;
    plot(w, [gdH1; gdH2; gdH3]);
    hold on;
    H = H3;
    p = p3;
    X = X3;
    for i=1:100
        wz = fndZeroCrs(H);
        SMtrx = pSens2(p, wz);
        [lgHz, phHz, gdHz, dLdWz, dTdWz] = AnlzDH(H, wz);
        Y = setY(gdHz, T1, T2);
        dX = (SMtrx + Pmin)\Y; % Calculate the changes in the pole frequencies
        X = X - updK*dX;
        p = updP2(p, X);
        H = zpk(z, p, k);
        [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w);
        plot(w, gdH);
              a = 1;
    end
 
    a = 1;


