function [X6, K, X, k1, k2] = rmv2Poles(X1, wp, P1, P2)
% RMV2POLES(wp, P1, P2) returns the residue and reactive part for moving two poles to loss pole positions
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

tol = 2e-6;
X1P1 = evalfr(X1, P1);
X1P2 = evalfr(X1, P2);
K = (X1P2 - X1P1)/(1/(P1 - wp) - 1/(P2 - wp));
K = real(K);
X = -X1P1 - K/(P1 - wp);
X = imag(X)*j;
tf1 = tf([K], [1 -wp]);
X2 = simpl(tf(X1) + X + tf1, 2e-6);
X3 = invert_zpk(X2);
[X4, k1] = rmv_pole(X3, P1);
[X5, k2] = rmv_pole(X4, P2);
X6 = invert_zpk(X5);
sprintf('Condition Number: %0.5g', condition(X6))