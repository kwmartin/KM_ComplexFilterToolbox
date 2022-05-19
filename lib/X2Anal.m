function [lgHz, phHz, gdHz, dLdWz, dTdWz] =  X2Anal(H, X, w)
%   [lgH2, phH2, gdH2, dLdW2, dTdW2] =  X2Anal(H, X) updates the poles of H based on X
%   and then analyezes for the group delay and derivatives at the group delay peaks.
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

    [z, p1, k] = sortZPK(H);
    p2 = updP(p1, X);
    H2 = zpk(z, p2, k);
    [lgH2, phH2, gdH2, dLdW2, dTdW2] = AnlzDH(H2, w);
    wz = fndZeroCrs(w, H2);
    [lgHz, phHz, gdHz, dLdWz, dTdWz] = AnlzDH(H2, wz);
    a = 1;