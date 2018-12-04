function X2 = fixRes(X1)
% X2 = fixRes(X1) returns TF with small parts of Rem set to zero
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

[n, d] = tfdata(X1, 'v');
[Ks, Pls, Rem] = residue(n, d);
if length(Rem) == 2
    if abs(real(Rem(2))) < 1e-4
        Rem(2) = imag(Rem(2))*j;
    end
    if abs(imag(Rem(2))) < 2e-6
        Rem(2) = real(Rem(2));
    end
    if abs(imag(Rem(1))) < 1e-5
        Rem(1) = real(Rem(1));
    end
    [n, d] = residue(Ks, Pls, Rem);
    X2 = zpk(tf(n, d));
elseif length(Rem) == 1
    if abs(real(Rem)) < 1e-4
        Rem = imag(Rem)*j;
    end
    if abs(imag(Rem)) < 2e-6
        Rem = real(Rem);
    end
    [n, d] = residue(Ks, Pls, Rem);
    X2 = zpk(tf(n, d));
else
	X2 = X1;
end
