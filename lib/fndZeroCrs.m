function fz = fndZeroCrs(deltF,H)
%   indc = fndZeroCrs(deriv,p) finds the zero-crossings of the derivative function used in
%   finding peaks for adapting the poles to get equiripple group delay of a digital filter
%   Inputs are the frequency vector (in Hz), the derivatives at those frequencies, and the
%   pole positions; the angles of the poles are used to determine the starting and endpoints
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

    [z, p, k] = sortZPK(H);
    f1 = angle(p)./(2*pi);
    frng = 1.02*[f1(1) f1(end)];
    f = frng(1):deltF:frng(2);
    w = 2*pi*f;
    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w);

    %dTdW2 = gltchRmv(dTdW);
    dTdW2 = medfilt1(dTdW);
    indc = fndZeroInd(f,dTdW2,p);
    f2 = f(indc + 1);
    f1 = f(indc);
    dd2 = dTdW(indc + 1);
    dd1 = dTdW(indc);
    fz = f1 - dd1.*(f2 - f1)./(dd2 - dd1);

    a=1;