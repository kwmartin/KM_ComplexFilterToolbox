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

function z = s2z(s,wp)
%S2Z Convert a frequency s=jw in s domain to a value in the transformed z domain.
%
%   Z = S2Z(S,W1,W2) is used to transform a loss-pole in the s domain into the z
%   domain for filter design. The passband is between w1 and w2 for
%   complex filters.  
%

%   Ken Martin: 11/24/03
%   Revised:
%   Copyright 2003 Ken Martin 
%   $Revision: 0.01 $  $Date: 11/24/03

z = sqrt((s - j*wp(2))./(s - j*wp(1)));