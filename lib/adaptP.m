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

    deltF = 1e-5;
    
    [z, p, k] = sortZPK(H);
    a = angle(p);
    m = abs(p);
    a1 = tan(1.03*a);
    p1 = m.*exp(j*a1);
    H1 = zpk(z, p1, k);
    f1 = angle(p)./(2*pi);
    frng = 1.1*[f1(1) f1(end)];
    f = frng(1):deltF:frng(2);
    w = 2*pi*f;
    [lgH0, phH0, gdH0, dLdW0, dTdW0] = AnlzDH(H1, w);
    fz = fndZeroCrs(deltF, H1);
    wz = 2*pi*fz;
    [lgHz, phHz, gdHz, dLdWz, dTdWz] = AnlzDH(H1, wz);
    sens = pSens(p1, fz);
    Np = length(p1);
    Nc = fix(Np/2);
    GD1 = gdHz(Np);
    GD2 = GD1 - DT;
    Y = setY(gdHz, DT, GD1, GD2);
    X = [real(p1(1:Nc)); imag(p1(1:Nc))];
    SMtrx = dTdP(sens);
    Pmin = 1e-6.*diag(ones(1,Np - 1));
    Sinv = inv(SMtrx + Pmin);
    dX = (SMtrx + Pmin)\(Y); % Calculate the changes in the pole frequencies
    X = X + 0.1*dX;
    p2 = updP(p1, X);
    H2 = zpk(z, p2, k);
    [lgH2, phH2, gdH2, dLdW2, dTdW2] = AnlzDH(H2, w);
    fz = fndZeroCrs(deltF, H2);
    wz = 2*pi*fz;
    [lgHz, phHz, gdHz, dLdWz, dTdWz] = AnlzDH(H2, wz);
    sens2 = pSens(p2, fz);
    SMtrx2 = dTdP(sens2);
    Y = setY(gdHz, DT, GD1, GD2);
    dX = (SMtrx + Pmin)\(Y); % Calculate the changes in the pole frequencies
    X = X + 0.1*dX;
    p3 = updP(p2, X);
    H3 = zpk(z, p3, k);
    [lgH3, phH3, gdH3, dLdW3, dTdW3] = AnlzDH(H3, w);
    figure;
    plot(f, [gdH0; gdH2; gdH3]);
    hold on;
    H = H3;
    p = p3;
    for i=1:10
        [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w);
        plot(f,gdH);
        fz = fndZeroCrs(deltF, H);
        wz = 2*pi*fz;
        [lgHz, phHz, gdHz, dLdWz, dTdWz] = AnlzDH(H, wz);
        sens = pSens(p, fz);
        SMtrx = dTdP(sens);
        Y = setY(gdHz, DT, GD1, GD2);
        dX = (SMtrx + Pmin)\(Y); % Calculate the changes in the pole frequencies
        X = X + 0.1*dX;
        p = updP(p, X);
        H = zpk(z, p, k);
    end
 
    a = 1;


