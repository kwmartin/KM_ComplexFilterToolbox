function h = dAs10_dz(wsz,As,w)
% h = dAs10_dz(wsz,As,w) find derivate of stopband specs
% This is a simple program for calculating the derivative of stopband
% specifications in log10 to the transformed variable z
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

As = As/10.0;
ls = length(w);
h = zeros(ls,1); % More convenient for loop below

for i = 1:ls
    if w(i)~= wsz(1)
        w1(i) = w(i) - 1e-5;
    else
        w1(i) = w(i);
    end

    if w(i)~= wsz(length(wsz))
        w2(i) = w(i) + 1e-5;
    else
        w2(i) = w(i);
    end

    a2(i) = interp1(wsz,As,w2(i));
    a1(i) = interp1(wsz,As,w1(i));
    h(i) = (a2(i) - a1(i))/(w2(i) - w1(i));
    if isnan(h)
        keyboard;
    end
end