function SMtrx = pSens2(p, w)
%   sens = pSens2(p, w) finds the sensitivities of the group delay
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
    sens = zeros(np, npts);
    for l = 1:np
        % Note, in the following two negative signs cancelled out
        sens(l, :) = eS./((eS - p(l)*onesVctr).^2);
    end
    
    Nr = fix(np - 1);
    Nc = fix(Nr/2);
    SMtrx = zeros(Nr,Nr);
    for i = 1:Nr
        for l = 1:Nc
            SMtrx(i, 2*l - 1) = real(sens(l, i)) + real(sens(np - l + 1, i));
            SMtrx(i, 2*l) = -imag(sens(l, i)) - imag(sens(np - l + 1, i));
        end
    end
    a = 1;
