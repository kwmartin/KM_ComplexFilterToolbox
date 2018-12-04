function lddr2 = scaleLddr(lddr, scaleFctr)
% frequency scale ladder; scaleFctr > 1 makes L's and C's smaller
% all L's and C's are multiplied by 1/scaleFctr
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

  lddr2 = ladderClass(lddr);
  NmbElems = lddr.size;
  mltFctr = 1/scaleFctr;
  for i = 1:NmbElems
    lddr2.ladderElems(i).L = mltFctr*lddr.ladderElems(i).L;
    lddr2.ladderElems(i).C = mltFctr*lddr.ladderElems(i).C;
  end
