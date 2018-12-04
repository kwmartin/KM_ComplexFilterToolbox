function [X5, k, K] = rmvUsinPl(X1, P, Irmv)
%   RMVUSINGS(wp, P1, P2) returns the residue and reactive part for moving two poles to loss pole positions
%   as 11/25/2018 deprecated and appears is not being currently used
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
warning('off', 'Control:ltiobject:ZPySComplex');

tol = 2e-6;
[n, d] = tfdata(X1, 'v');
[Ks, Pls, Rem] = residue(n, d);
[Pls Inds] = sort(imag(Pls));
Pls = Pls*j;
Prmv = Pls(Irmv);
X1P = evalfr(X1, P);
k = -X1P*(P - Prmv);
k = real(k);
tf1 = tf([k], [1, -Prmv]);
X2 = simpl(tf(X1)  + tf1, 2e-6);
X3 = invert_zpk(X2);
[X4, K] = rmv_pole2(X3, P);
X5 = invert_zpk(simpl(X4));
sprintf('Condition Number: %0.5g', condition(X5))