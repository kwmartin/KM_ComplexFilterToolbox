 function sens = plSens(p, w)
%   sens = plSens(p, w) finds the sensitivities of the group delay
%   at frequencies w in rad. with respect to the pole real and imaginary
%   parts
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
    w = w(:);
    eS = exp(j*w);
    onesVctr = ones(size(w));
    np = length(p);
    npts = length(w);
    sens = zeros(npts + 1, np*2);
    for l = 1:np
        % Note, in the following two negative signs cancelled out
        sens(1:npts, l) = real(eS./((eS - p(l)*onesVctr).^2));
        sens(1:npts, l+np) = -imag(eS./((eS - p(l)*onesVctr).^2));
    end
    for l = 1:np/2
        sens(npts+1, l) = 1;
        sens(npts+1, np - l+1) = -1;
        sens(npts+1, l+np) = 1;
        sens(npts+1, 2*np - l+1) = 1;
    end
    a = 1;
