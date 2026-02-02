function H2 = makeConj(H)
%  H2 = makeConj(X0) makes to poles and zeros of a zpk object exactly complex conjugates
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
    [z p k] = sortZPK(H);
    Nz = fix(length(z)/2);
    Np = fix(length(p)/2);
    for i = 1:Nz
        rlPrt = 0.5*(real(z(i)) + real(z(end - i +1)));
        imPrt = 0.5*(imag(z(end - i +1)) - imag(z(i)));
        z(end - i +1) = rlPrt + j*imPrt;
        z(i) = rlPrt - j*imPrt;
    end
    for i = 1:Np
        rlPrt = 0.5*(real(p(i)) + real(p(end - i +1)));
        imPrt = 0.5*(imag(p(end - i +1)) - imag(p(i)));
        p(end - i +1) = rlPrt + j*imPrt;
        p(i) = rlPrt - j*imPrt;
    end

    H2 = zpk(z, p, k);
    a=1;
