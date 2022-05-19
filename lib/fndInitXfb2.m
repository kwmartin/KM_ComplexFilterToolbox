function Xfbi = fndInitXfb2(Xfb,Xin,npts)
%   Xfbi = fndInitXfb2(Xfb,xin,npts) finds the initial values required for
%   complex resonator outputs when switching directions
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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
    N = size(Xfb,2);
    xfb = Xfb(end - (npts-1):end,:);
    xin = Xin(end - (npts-1):end);
    nrmFb = sqrt(sum(xfb.*conj(xfb)));
    nrmXi = sqrt(sum(xin.*conj(xin)));
    denom = nrmFb.*nrmXi;
    xiRpt = repmat(xin,1,N);
    dprdct = sum(xfb.*conj(xiRpt));
    ex = dprdct./denom;
    dph = angle(ex);
    ph1 = angle(Xfb(end,:));
    k = abs(Xfb(end,:));
    newPh = ph1 - 2.*dph;
    Xfbi = k.*exp(j*newPh);
    a = 1;
