function X2 = simpl(X0, tol)
%   X2 = simpl(X0, tol) removes poles and zeros close to zero
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
    global imagRoots;
    warning('off', 'Control:ltiobject:TFComplex');
    warning('off', 'Control:ltiobject:ZPKComplex');
    if nargin < 2
        tol =  1e-6;
    end

    %X1 = minreal(X0, 5e-7);
    X1 = X0;
    [z, p, k, T] = zpkdata(X1, 'v');
    if ~isempty(z)
        maxz = max(abs([z]));
        z(abs(z) < tol) = 0;
        z(abs(imag(z)) < tol) = real(z(abs(imag(z)) < tol));
        z(abs(real(z)) < tol) = imag(z(abs(real(z)) < tol))*j;
    end
    if ~isempty(p)
        maxp = max(abs([p]));
        p(abs(p) < tol) = 0;
        p(abs(imag(p)) < tol) = real(p(abs(imag(p)) < tol));
        p(abs(real(p)) < tol) = imag(p(abs(real(p)) < tol))*j;
    end
    if (abs(real(k)) > tol) && (abs(imag(k)/real(k)) < tol), k = real(k); end
    if (abs(imag(k)) > tol) && (abs(real(k)/imag(k)) < tol), k = imag(k)*j; end
    %z = sort(imag(z))*1j;
    %p = sort(imag(p))*1j;
    %X2 = minreal(zpk(z, p, k), 1e-6);
    if imagRoots
        z = imag(z)*j;
        p = imag(p)*j;
    end
    if T == 0
        X2 = zpk(z, p, k);
    else
        X2 = zpk(z, p, k, T);
    end
