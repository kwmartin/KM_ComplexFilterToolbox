function drvs = hxDeriv(hx, w)
%   drvs = hxDeriv(hx, w) evaluates the derivatives oftransformed residues
%   with respect to w, at wx in rad.
%   hx is a cell array of the transformed group delay residues.
%   wx is multiplied by j before evaluating.
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

    sx = j*w;
    N = length(hx);
    gd = 0;
    zrs = {};
    pls = {};
    nx = {};
    px = {};
    dnx = {};
    dps = {};
    derivs = {};
    onesV = ones(size(w));
    drvs = zeros(size(w));
    for i = 1:N
        zrs{i} = hx{i}.z{1};
        pls{i} = hx{i}.p{1};
        nx{i} = (sx - zrs{i}(1)).*(sx - zrs{i}(2));
        px{i} = (sx - pls{i}(1)).*(sx - pls{i}(2));
        dnx{i} = -2*w - j*(zrs{i}(1) + zrs{i}(2));
        dpx{i} = -2*w - j*(pls{i}(1) + pls{i}(2));
        derivs{i} = (hx{i}.k)*(dnx{i}.*px{i} - nx{i}.*dpx{i})./(px{i}.*px{i});
        drvs = drvs + derivs{i};
    end
    drvs = real(drvs);
    a=1;
