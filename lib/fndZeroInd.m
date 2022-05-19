function indc = fndZeroInd(w,deriv,p)
%   indc = fndZeroInd(w,deriv,p) finds the zero-crossings of the derivative function used in
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

    wpi = angle(p);
    [m ind] = min(abs(w - wpi(1)));
    ind1 = ind - 2;
    [m ind] = min(abs(w - wpi(end)));
    ind2 = ind + 2;
    w2 = w(ind1:ind2);
    deriv2 = deriv(ind1:ind2);
    vct2 = [deriv2(2:end) deriv2(end)];
    indc3 = find(deriv2.*vct2 < 0);
    indc = indc3 + ind1 - 1;
    if length(indc) ~= length(p)*2 - 1
        error('Length of zero crossing vector (%d) is not equal to %d', ...
            length(indc), length(p)*2 - 1);
    end
    a=1;