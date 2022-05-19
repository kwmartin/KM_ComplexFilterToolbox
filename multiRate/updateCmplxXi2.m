function [Xi, Xerr, Xout] = updateCmplxXi(xin, G, rsntrs)
%   [Xi, Xerr, Xout] = updateCmplxXi(xi, G, rsntrs) updates resonator input when xin changes
%   given current state
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
    trnc = @(val, d) (fix(val*2^d) + rand())/2^d;

    N = length(rsntrs);
    xsum = 0.0;
    Xout2 = 0.0;

    % xi = trnc(xin, 12);
    xi = xin;

    for j = 1:N
        xsum = xsum + rsntrs(j).Xo;
    end
    Xout = xsum;
    Xerr = xi - xsum;
    Xi = G*Xerr;
    a = 1;
