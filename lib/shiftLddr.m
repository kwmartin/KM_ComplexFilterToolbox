function lddr2 = shiftLddr(lddr, shiftFctr)
% frequency shifts a ladder on the jw axis. This achieved
% shifting all the reactive elements either in series with an
% inductor or in parallel with a capacitor
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
  lddr2 = ladderClass(lddr);
  NmbElems = lddr.size;
  for i = 1:NmbElems
    if abs(lddr2.ladderElems(i).L) > tol
      X = imag(lddr2.ladderElems(i).X);
      lddr2.ladderElems(i).X = (X*j - lddr2.ladderElems(i).L*shiftFctr*j);
    end
    if abs(lddr2.ladderElems(i).C) > tol
      Y = imag(lddr2.ladderElems(i).Y);
      lddr2.ladderElems(i).Y = (Y*j - lddr2.ladderElems(i).C*shiftFctr*j);
    end
  end
