function xout = lpFltr3rdOrdr(xin,k)
%   out = lpFltr3rdOrdr(xin,ks) lowpass filters xin with a 3'rd order
%   filter. The bandwidth is approximatealy k/(2*pi)) 
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
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
    k1 = k; k2 = 0.875; k3 = 0.125;
    npts = length(xin);
    x1 = 0; x2 = 0; x3 = 0;
    xout = zeros(size(xin));
    for i = 1:npts
        x4 = x2 + k3*xin(i);
        x1i = k1*(xin(i) - x4) + x1;
        x2i = k1*(x1i - k2*x4) + x2;
        xout(i) = x3;
        x3i = k1*(x4 - x3) + x3;
        x1 = x1i; x2 = x2i; x3 = x3i;
    end
    a = 1;