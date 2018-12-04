function [H4, k] = rmvS(H1)
%   [H4, k] = rmvS(H1) removes a loss pole at infinity
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

[z, p, k] = zpkdata(H1, 'v');
if ~(length(z) == (length(p) + 1))
  error('To remove an s term, the numerator must higher order than the denominator by 1');
end

tf1 = tf([k, 0], [1]);
H2 = tf(H1) - tf1;
H3 = simpl2(H2);
H4 = invert_zpk(H3);
sprintf('Condition Number: %0.5g', condition(H4))