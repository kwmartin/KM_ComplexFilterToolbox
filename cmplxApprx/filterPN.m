function [P, N] = filterPN(fpT, data)
%   y = filterPN(fpT, data) assumes the data is a non-ideal complexoid at fPt
%   and filters for the positive and negative components using a Hilbert Transform
%   implemented using an all-pass filter
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

    allPassOut = filterAllPass(fpT, data);
    posOid = 0.5*(data + j*allPassOut);
    negOid = 0.5*(data - j*allPassOut);
%   Find P and N by demodulating to dc
    Pdc = posOid.*conj(ejwT);
    Ndc = negOid.*ejwT;
    n = length(Pdc);
    P = mean(Pdc(floor(n/2):n));
    N = mean(Ndc(floor(n/2):n));
    prdct = P.*ejwT + N.*conj(ejwT);
    err = data - prdct;
    shw = [prdct, data, err];
    n = length(ejwT);
%S    shw(n-32:n, :)
    a = 1;
    