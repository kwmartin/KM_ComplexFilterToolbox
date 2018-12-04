function [p pDer] = plyDer(c, x)
% [p pDer] = plyDer(c, x) returns value and derivative of polynomial c at x
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

c = c(:).'; % ' in comment stops coloration in sublime-text
n = length(c);
if n <= 2
  display('plyDer is only supported for order greater than 1')
  return
end
p = c(1).*x + c(2);
pDer = c(1);
% if one wants to do long division, turn pDer into vector
for i = 3:n
  pDer = p + pDer.*x;
  p = c(i) + p.*x;
end
a=1;