function [lddr, fail] = doRmvls(rmvlTypes, rmvlOrdr, X0, wps, ni)
% [lddr, fail] = doRmvls(rmvlTypes, rmvlOrdr, X0, wps, ni) automates ladder removals
% Currently deprecated, but expected to be replaced by an updated version as there are
% many additional removals
%
% note: loss poles (wps) are real, not imaginary as in many other routines; to be changed
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

nmbRmvls = length(rmvlOrdr);
fail = false;
lddr = ladderClass();

for i=1:nmbRmvls
  rmvlType = rmvlTypes(i);
  if rmvlOrdr(i) > 0
    wp = wps(rmvlOrdr(i));
  end

  if (rmvlType == 1 || rmvlType == 2 || rmvlType == 3 || rmvlType == 4)
    [elem1, X1, fail] = extrmRmvl(X0, rmvlType);
    lddr.addElem(elem1);
    if fail
      break
    end
  elseif (rmvlType == 5 || rmvlType == 6 || rmvlType == 7 || rmvlType == 8)
    [elem1, elem2, X1, fail] = finiteRmvl(X0, wp, rmvlType);
    lddr.addElem(elem1);
    lddr.addElem(elem2);
    if fail
      break
    end
  else
    error('Incorrect Removal Type')
  end

  X0 = X1;
end
if fail
  disp(sprintf('failed at iteration %d', i))
end
