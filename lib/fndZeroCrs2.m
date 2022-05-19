function wz = fndZeroCrs2(H,fgd)
%   indc = fndZeroCrs2(H) finds the zero-crossings of the derivative function used in
%   finding peaks for adapting the poles to get equiripple group delay of a digital filter
%   Inputs are the frequency vector (in Hz), the derivatives at those frequencies, and the
%   pole positions; the angles of the poles are used to determine the starting and endpoints
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

    x2w = @(x,wi)(2.*atan((wi(2)*ones(size(x)) + wi(1).*x)./(2*ones(size(x)) + 2.*x)));
    hgdx = hgdxMake(H,fgd);
    xcrss = fndZrCrss(hgdx);
    wpx = 2*tan(fgd*pi);
    wz = sort(x2w(xcrss,wpx));

    a=1;