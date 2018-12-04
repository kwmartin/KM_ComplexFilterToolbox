function [outArry, outElem, indx] = chooseX(func, inArry)
% chooseX(func, inArry) applies min(func) to inArry
% and returns the indx and the array with the min removed
% It's a utility function used in grouping zeros and poles
% when designing a digital filter
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
  [minCmp, indx] = min(func(inArry));
  outArry = inArry;
  outElem = inArry(indx);
  outArry(indx) = [];