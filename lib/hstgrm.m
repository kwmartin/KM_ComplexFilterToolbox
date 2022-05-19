function [cnts edgVals] = hstgrm(x,mn,mx,binWdth)
%   cnts = hstgrm(x,mn,mx,nmbBins) gives counts of x in each bin with nmbBins
%   between mn and mx (i.e. each bin is (mx - mn)/nmbBins wide)
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
    
    nmbBins= round((mx - mn)/binWdth);
    edgVals = zeros(nmbBins,1);
    mxVals = zeros(nmbBins,1);
    cnts = zeros(nmbBins,1);
    for i = 0:nmbBins - 1
        edgVals(i+1) = mn + binWdth*i;
        mxVals(i+1) = mn + binWdth*(i+1);
        indxs = find((x >= edgVals(i+1)) & (x < mxVals(i+1)));
        cnts(i+1) = length(indxs);
    end
        
    a = 1;