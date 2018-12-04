function [H3, K] = rmv_pole(H1, wp, tol)
% RMV_POLE(H1, wp) returns the residue and remaining transfer function after removing a pole
% consider using remove_pole() for better accuracy
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
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

if nargin < 3
    tol =  1e-5;
end
[z, p, k] = zpkdata(H1, 'v');
indx = find(abs(p - wp) < tol);
p(indx) = [];
H2 = zpk(z, p, k);
K = evalfr(H2, wp);
tf1 = tf([K], [1, -wp]);
H3 = simpl2(tf(H1) - tf1, tol);
