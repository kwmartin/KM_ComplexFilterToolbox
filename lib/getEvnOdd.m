%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [Eevn, Eodd] = getEvnOdd(Epl)

Ne = length(Epl);
if mod(Ne, 2) == 1
    sgns = (-1).^(0:(Ne-1));
else
    sgns = (-1).^(1:(Ne));
end
Eevn = (Epl + conj(Epl).*sgns)/2;
Eodd = (Epl - conj(Epl).*sgns)/2;
