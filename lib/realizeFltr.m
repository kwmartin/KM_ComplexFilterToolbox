% This is an example of getting reactance functions
% Its been deprecated as of 11/23/2018
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

exmpl1.m
Eodd = getOdd(E);
Eeven = getEven(E);
Fodd = getOdd(F);
Feven = getEven(F);
[X1o, X1s, X2o, X2s] = mkXs(peven, Eevn, Eodd, Feven, Fodd);
