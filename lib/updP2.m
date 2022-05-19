function p2 = updP2(p1, X)
%   p2 = updP(p1, X) updates the poles based on the X vector used in the adaptation
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

    p2 = p1;
    Nx = length(X);
    Np = Nx/2;
    pr = X(1:2:Nx-1);
    pq = X(2:2:Nx);
    p2(1:Np) = pr + j*pq;
    p2(Np+2:end) = conj(p2(Np:-1:1));

    a = 1;