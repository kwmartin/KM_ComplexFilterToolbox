function ord = fndOrdr(X)
%   Prune leading zeros of numerator and denominator and then return
%   the order of a system object
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
  tol = 1e-7;
  [num, den] = tfdata(X, 'v');
  if ~isempty(num(num~=0))
    while (abs(num(1)) <= tol)
      num = num(2:end);
    end
    ordn = length(num) - 1;
  else
    ordn = 0;
  end
  while (abs(den(1))  <= tol)
    den = den(2:end);
  end
  ordd = length(den) - 1;
  ord = [ordn, ordd];
