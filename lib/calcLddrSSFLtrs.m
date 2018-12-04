function TFs = calcLddrSSFLtrs(lddr)
%  Fltrs = calcLddrSSFLtrs(lddr) returns discrete-time nodal state-space transfer functions
%  of a ladder object. The transfer functions can be used to realize a digital realization
%  based on a signal-flow-graph simulation approach
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

  NmbElems = lddr.size;
  N = 2*(NmbElems -1)/3 + 1;
  if mod(N, 2) == 0
    error('The filter order must be odd to make a digital SFG-based filter');
  end

  elems = lddr.ladderElems;
  elem0 = ladderElem(0, 0, 0, 0, 'SHY');

  if lddr.R1 ~= 0
      elemin = ladderElem(0, 0, 0, 1/lddr.R1, 'SRY');
  end
  TFs={};
  TFs{1} = findNodeTF(elemin, elems(1), elems(2));

  if lddr.R2 ~= 0
    elems(NmbElems).Y = elems(NmbElems).Y + 1/(lddr.R2);
    elemout = ladderElem(0, 0, 0, 0, 'SRY');
  end
  TFs{N} = findNodeTF(elems(NmbElems - 1), elems(NmbElems), elemout);

  elemNmb = 2;
  for i = 2:(N - 1)
    if mod(i, 2) == 0
      TFs{i} = findNodeTF(elems(elemNmb), elem0, elems(elemNmb + 1));
      elemNmb = elemNmb + 1;
    else
      TFs{i} = findNodeTF(elems(elemNmb), elems(elemNmb + 1), elems(elemNmb + 2));
      elemNmb = elemNmb + 2;
    end
  end

  a=1;