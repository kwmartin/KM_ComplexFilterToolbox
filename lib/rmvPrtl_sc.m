function H2 = rmvPrtl_sC(H1, C, tol)
%   RMVPRTL_SC(H1, wp) removes sC from H1; this is normally a partial removal of s=inf
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

    if nargin < 3
        tol =  2e-6;
    end

	tfC = tf([C 0], [1]);
	H2 = simpl(tf(H1) - tfC, tol);
