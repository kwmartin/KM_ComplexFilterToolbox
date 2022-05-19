function wcrss = fndZrCrss(hx)
%   zrcrss = fndZrCrss(hx) finds the zero crossings of the derivate of the
%   group delay in the transformed domain
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

    zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);
    dw = 1e-3;
    w = 0:dw:100;
    dgd = hxDeriv(hx, w);
    zrcrss = zci(dgd);
    if zrcrss(end) == length(w) zrcrss(end) = []; end
    onesv = ones(size(zrcrss));
    ddw = 1e-6*onesv;
    ddgmin = 1e-10*onesv;
    dgzrcs1 = dgd(zrcrss);
    wcrss = w(zrcrss);
    wcrss = wcrss(:);
    dgzrcs1 = dgzrcs1(:);
    dgzrcs2 = hxDeriv(hx, wcrss + ddw);
    ddgd = (dgzrcs2 - dgzrcs1)./ddw;
    deltaW = -dgzrcs1./(ddgd + ddgmin);
    wcrss = wcrss + deltaW;
    for i = 1:5
        dgzrcs1 = hxDeriv(hx, wcrss);
        dgzrcs2 = hxDeriv(hx, wcrss + ddw);
        % ddgd = (dgzrcs2 - dgzrcs1)./ddw;
        deltaW = -dgzrcs1./(ddgd + ddgmin);
        wcrss = wcrss + deltaW;
    end
    a=1;
