function [X5, X] = rmvUsingX(X1, P)
%   [X5, X] = rmvUsingX(X1, P) removes a loss pole using a partial removal
%   of a complex reactance function
%   It's been deprecated as of 11/25/2018
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

tol = 2e-6;
X1P = evalfr(X1, P);
X = -X1P;
X = imag(X)*j;
X2 = simpl(tf(X1)  + X, 2e-6);
X3 = invert_zpk(X2);
[X4, k1] = rmv_pole(X3, P);
X5 = invert_zpk(X4);
sprintf('Condition Number: %0.5g', condition(X5));