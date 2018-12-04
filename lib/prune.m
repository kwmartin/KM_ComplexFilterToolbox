function [X1] = prune(X0)
% [X1] = prune(X0) simplifies X0 and removes leading zeros
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

  tol = 2*sqrt(eps);
  [n, d] = tfdata(X0, 'v');
  n = real(n);
  d = real(d);
  if ((n(end) == 0) && (d(end) == 0))
    n = n(1:end - 1)
    d = d(1:end - 1)
  end
  n(abs(n) < tol) = 0;
  d(abs(d) < tol) = 0;
  if n ~= 0
    while (n(1) == 0)
      n = n(2:end);
    end
  end
  while (d(1) == 0)
    d = d(2:end);
  end
  X1 = tf(n, d);
