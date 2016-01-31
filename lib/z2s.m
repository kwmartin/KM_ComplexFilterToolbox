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

function s = z2s(z,wp)
%Z2S Convert a value in the z domain to a value in the s domain.
%
%   S = S2Z(Z,WP) is used to transform a pole in the z domain into the s
%   domain for filter design. The passband is between wp(1) and wp(2) for
%   complex filters.  
%

%   Ken Martin: 11/24/03
%   Revised:
%   Copyright 2003 Ken Martin 
%   $Revision: 0.01 $  $Date: 11/24/03

s = j*(wp(2) - wp(1).*z.*z)./(1 - z.*z);
s(isnan(s)) = j*1e5;