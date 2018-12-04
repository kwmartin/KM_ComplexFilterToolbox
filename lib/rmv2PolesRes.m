function [X3, k1, k2] = rmv2PolesRes(X1, P1, P2, tol)
% RMV_POLE(H1, wp) returns the residues and remaining transfer function after two poles
%   It uses Matlab's built in residue() function
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

if nargin < 4
    tol =  2e-7;
end
[Ks, Pls, Rem] = findRes(X1);
%Pls = cleanParts(Pls);
indice = find(abs(imag(Pls)*j - P1) < 4e-6);
if isempty(indice)
  error('Pole Removals Failed, P1');
end
Pls(indice) = [];
k1 = real(Ks(indice));
Ks(indice) = [];
indice = find(abs(imag(Pls)*j - P2) < 4e-6);
if isempty(indice)
  error('Pole Removals Failed, P2');
end
Pls(indice) = [];
k2 = real(Ks(indice));
Ks(indice) = [];
[n, d] = residue(Ks, Pls, Rem);
X2 = tf(n, d);
if max(fndOrdr(X2)) + 2 ~= max(fndOrdr(X1))
  error('Pole Removals Failed');
end
X3 = simpl(zpk(X2), tol);
%X3 = zpk(X2);
X3.k = real(X3.k);
