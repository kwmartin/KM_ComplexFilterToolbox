function y = cleanParts2(x, tol) % cleans residue remainder
%   assumes the two elements in x are residue remainder,
%   the first element must be real and the second element is imaginary
%   if its real part is smaller than default 1e-4 (can be specified)
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
    if nargin < 2
        tol =  1e-4;
    end

    rem1 = x(1);
    rem2 = x(2);
    if real(rem2) < tol rem2 = imag(rem2)*j; end
    if abs(rem2) < tol/10 rem2 = 0; end
    rem1 = real(rem1);
    y = [rem1 rem2];
