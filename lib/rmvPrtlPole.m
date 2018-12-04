function X1 = rmvPrtlZero(X0, wp, K, tol)
%   X1 = rmvPrtlZero(X0, wp, K, tol) removes sC from H1; this is normally a partial removal of s=inf
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
	warning('off', 'Control:ltiobject:TFComplex');
	warning('off', 'Control:ltiobject:ZPKComplex');

    if nargin < 4
        tol =  2e-6;
    end

	tfZ = tf([K], [1 -wp]);
	X1 = simpl(tf(X0) - tfZ, tol);
