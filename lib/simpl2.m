function [X2] = simpl2(X1, tol)
% [X2] = simpl2(X1, tol) simplifies a transfer function by dropping small residues
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
if nargin < 2
    tol =  1e-5;
end

[Ks, Pls, Rem] = findRes(X1);
indice1 = find(abs(Ks) < tol);
Pls(indice1) = [];
Ks(indice1) = [];
Rem = cleanParts(Rem, 5);
[n, d] = residue(Ks, Pls, Rem);
X2 = simpl(zpk(tf(n, d)), tol);
K = X2.K;
if (abs(real(K)) < tol) K = j*imag(K); end
if (abs(imag(K)) < tol) K = real(K); end
X2.K = K;
