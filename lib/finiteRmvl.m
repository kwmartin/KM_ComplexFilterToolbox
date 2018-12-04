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

function [elem1, elem2, X1, fail] = finiteRmvl(X0, wp, rmvlType)
  switch rmvlType
    case 5
      [K0, K1, K2, X1, fail] = rmvl3(X0, wp);
      elem1 = ladderElem(0, K0, 0, 0, 'SRC');
      elem2 = ladderElem(K1, K2, 0, 0, 'SHLC');
    case 6
      X0 = 1/X0;
      [K0, K1, K2, X1, fail] = rmvl3(X0, wp);
      elem1 = ladderElem(K0, 0, 0, 0, 'SHL');
      elem2 = ladderElem(K2, K1, 0, 0, 'SRLC');
      [num, den] = tfdata(X1, 'v');
      if ~isempty(num(num~=0))
        X1 = 1/X1;
      end
    case 7
      [K0, K1, K2, X1, fail] = rmvl4(X0, wp);
      elem1 = ladderElem(K0, 0, 0, 0, 'SRL');
      elem2 = ladderElem(K1, K2, 0, 0, 'SHLC');
    case 8
      X0 = 1/X0;
      [K0, K1, K2, X1, fail] = rmvl4(X0, wp);
      elem1 = ladderElem(0, K0, 0, 0, 'SHC');
      elem2 = ladderElem(K2, K1, 0, 0, 'SRLC');
      [num, den] = tfdata(X1, 'v');
      if ~isempty(num(num~=0))
        X1 = 1/X1;
      end
    otherwise
      error('finiteRmvl types must be either 5,6,7, or 8')
    end
    X1 = zpk(X1);
