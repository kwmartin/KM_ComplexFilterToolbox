function eply = getEven2(rts)
%   eply = getEven2(rts) returns the complex even polynomial of polynomial
%   defined by rts. It uses the polynomial class for better accuracy. In
%   the returned polynomial even terms are real and odd terms are complex
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

ply = polyClass(rts,1);
[Eevn, Eodd] = getEvnOddPly(ply);
eply = poly(Eevn.rts).*Eevn.K;
a=1;