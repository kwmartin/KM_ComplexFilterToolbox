function [X3, k] = rmv_pole2(X1, P, tol)
% [X3, k] = rmv_pole2(X1, P, tol) returns the residue and remaining transfer function after removing a pole
%   An improved pole removal function (as compared to rmv_pole())
%   another alternative is remove_pole(); we need to figure out which is better
%   and consolidate; currently we are using this rmv_pole2() for our examples
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
    tol =  2e-6;
end
[Ks, Pls, Rem] = findRes(X1);
indice = find(abs(imag(Pls)*j - P) < 4e-6);
if isempty(indice)
  error('Pole Removals Failed');
end

Pls(indice) = [];
k = real(Ks(indice));
Ks(indice) = [];
[n, d] = residue(Ks, Pls, Rem);
X2 = tf(n, d);
X3 = simpl(zpk(X2), tol);
X3 = fixRes(X3);