function [xy, ay] = trnsfrm_specdLP(ws,as,wp)
%   [xy, ay] = trnsfrm_specdLP(ws,as,wp) transform specifications to y domain
%   Returned specification frequencies are imaginary and in radians
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
%   for example: wsz = sqrt((wp(2) - ws./( wp(1) - ws))
%
%   This function is used to transform stopband specifications
%   to mapped domain and to order them. The passband is between
%   w1 and w2, the specification frequencies are in ws, and the
%   corresponding specifications are in as. The mapped
%   frequencies are in wz, and the re-ordered specifications are in az.  
%   Note: this transformation works for complex filters
%
%   Ken Martin: 11/24/03
%   Revised: 10/20/18

w2x = @(w, wi) ((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1)));
xs = w2x(2*pi*ws,wp);
xs(xs == -Inf) = Inf; % all specs are positive
[xy,i] = sort(xs);
ay = as(i);
a=1;