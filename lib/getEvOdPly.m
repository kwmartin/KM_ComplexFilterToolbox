function [Eevn, Eodd] = getEvOdPly(Epl)
%   Find even and odd parts of a polynomial object
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2019  Kenneth Martin
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

    if ~isa(Epl,'polyClass')
        error('getEvOdPly requires polyClass as an argument')
    end
    
    Eevn = (Epl + Epl')*0.5;
    Eodd = (Epl - Epl')*0.5;
    a=1;