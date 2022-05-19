function [X1, X2] = fndInitXs(Xfb,Xs, k)
%   [X1, X2] = fndInitXs(Xfb,Xs, k) finds the initial state vectors for a
%   desired Xfb and Xs for a resonator in a loop
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
    xi2 = Xs./2;
    X1 = (Xfb + k.*xi2)./2;
    X2 = xi2 - k.*X1;
    if k(1) == 0;
        X1(1) = Xfb(1);
        X2(1) = 0;
    end
    a = 1;
