function [z, p, k] = sortZPK(X0)
%   [z, p, k] = sortZPK(X0) returns the zeros, poles, and k of a system object
%   as vectors (for z and p). They are first sorted along the jw axis. This function
%   is primarily used during debug
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
    [z p k] = zpkdata(X0, 'v');
    [zi, indic] = sort(imag(z));
    z = real(z(indic)) + zi*j;
    [pi, indic] = sort(imag(p));
    p = real(p(indic)) + pi*j;
