function [P, N] = filterPN2(fpT, data)
%   y = filterPN2(fpT, data) assumes the data is a non-ideal complexoid at fPt
%   and filters for the positive and negative components using a complex bandpass
%   at either positive or negative frequencies and a notch at the opposite quandrant
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
    npts = length(data);
    dwT = 2*pi*fpT;
    freqPts = (dwT:dwT:dwT*npts)';
    ejwT = exp(j*freqPts);
    n = length(ejwT);

    EJWT = exp(j*2*pi*fpT);
    CEJWT = exp(-j*2*pi*fpT);
    gn = 1/(1 - CEJWT^2)
    k = 1/8;

    acoeffs = [1, (k - 1)*EJWT];
    bcoeffs = [0, k*EJWT, -k];;
    posOid = filter(gn.*bcoeffs, acoeffs, data);
    Pdc = posOid.*conj(ejwT);

    acoeffs = [1, (k - 1)*CEJWT];
    bcoeffs = [0, k*CEJWT, -k];;
    negOid = filter(gn.*bcoeffs, acoeffs, data);
    Ndc = negOid.*ejwT;

    P = mean(Pdc(floor(n/2):n));
    N = mean(Ndc(floor(n/2):n));
    prdct = P.*ejwT + N.*conj(ejwT);
    err = data - prdct;
    shw = [prdct, data, err];
    n = length(ejwT);
    shw(n-32:n, :)
    a = 1;
    