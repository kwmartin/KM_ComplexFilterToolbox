function s = z2s(z,wp)
%   s = z2s(z,wp) converts a value in the z domain to a value in the s domain
%   for filter design. The passband is between wp(1) and wp(2) for
%   complex filters.  
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

s = j*(wp(2) - wp(1).*z.*z)./(1 - z.*z);
s(isnan(s)) = j*1e5;