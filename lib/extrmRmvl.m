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

function [elem1, X1, fail] = extrmRmvl(X0, rmvlType)
  switch rmvlType
    case 1
      [K0, X1, fail] = rmvl1(X0);
      elem1 = ladderElem(0, K0, 0, 0, 'SRC');
    case 2
      X0 = 1/X0;
      [K0, X1, fail] = rmvl1(X0);
      elem1 = ladderElem(K0, 0, 0, 0, 'SHL');
      [num, den] = tfdata(X1, 'v');
      if ~isempty(num(num~=0))
        X1 = 1/X1;
      end
    case 3
      [K0, X1, fail] = rmvl2(X0);
      elem1 = ladderElem(K0, 0, 0, 0, 'SRL');
    case 4
      X0 = 1/X0;
      [K0, X1, fail] = rmvl2(X0);
      elem1 = ladderElem(0, K0, 0, 0, 'SHC');
      [num, den] = tfdata(X1, 'v');
      if ~isempty(num(num~=0))
        X1 = 1/X1;
      end
    otherwise
      error('extrmRmvl types must be either 1,2,3, or 4')
    end
