function [H2, k] = remove_pole(H1, wp)
% REMOVE_POLE(H1, wp) returns the residue and remaining transfer function after removing a pole
% from H1 using Matlab's residue function; the pole frequency wp is typically complex
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
%
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

tol = 2e-6;
[n, d] = tfdata(H1, 'v');
[Ks, Pls, Rem] = residue(n, d);
indice = find(abs(Pls - wp) < tol);
k = Ks(indice);
Pls(indice) = [];
Ks(indice) = [];
[n, d] = residue(Ks, Pls, Rem);
H2 = simpl(zpk(tf(n, d)));
if (abs(real(k)) > tol) && (abs(imag(k)/real(k)) < tol), k = real(k); end