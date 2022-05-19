function sens = pSens(p, w)
%   sens = pSens(p, w) finds the sensitivities of the group delay
%   at frequencies w in rad.
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

    eS = exp(j*w);
    onesVctr = ones(size(w));
    np = length(p);
    npts = length(w);
    rsens = zeros(np, npts);
    isens = zeros(np, npts);
    msens = zeros(np, npts);
    psens = zeros(np, npts);
    for l = 1:np
        % Note, in the following two negative signs cancelled out
        rsens(l, :) = real(eS./((eS - p(l)*onesVctr).^2));
        isens(l, :) = -imag(eS./((eS - p(l)*onesVctr).^2));
        ejP = exp(j*angle(p(l)));
        mP = abs(p(l));
        msens(l, :) = real((eS.*ejP)./((eS - p(l)*onesVctr).^2));
        psens(l, :) = -imag((eS.*ejP.*mP)./((eS - p(l)*onesVctr).^2));
    end
    sens.rsens = rsens;
    sens.isens = isens;
    sens.msens = msens;
    sens.psens = psens;
    a = 1;
