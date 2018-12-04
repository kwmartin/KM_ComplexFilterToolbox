function lddr2 = freqShftLddr(lddr, deltW)
% frequency shifts a ladder up or down the j axis
% This frequency shift goes through all the components of lddr, which
% is a ladderClass object, and changes the reactive (complex) frequency
% independent components. deltW is specified in rad.
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
  for i = 1:NmbElems
    switch lddr.ladderElems(i).type
      case 'SHC'
        lddr2.ladderElems(i).Y = lddr.ladderElems(i).Y - deltW*lddr.ladderElems(i).C*j;
      case 'SHL'
        lddr2.ladderElems(i).X = lddr.ladderElems(i).X - deltW*lddr.ladderElems(i).L*j;
      case 'SHLC'
        lddr2.ladderElems(i).X = lddr.ladderElems(i).X - deltW*lddr.ladderElems(i).L*j;
        lddr2.ladderElems(i).Y = lddr.ladderElems(i).Y - deltW*lddr.ladderElems(i).C*j;
      case 'SRC'
        lddr2.ladderElems(i).Y = lddr.ladderElems(i).Y - deltW*lddr.ladderElems(i).C*j;
      case 'SRL'
        lddr2.ladderElems(i).X = lddr.ladderElems(i).X - deltW*lddr.ladderElems(i).L*j;
      case 'SRLC'
        lddr2.ladderElems(i).X = lddr.ladderElems(i).X - deltW*lddr.ladderElems(i).L*j;
        lddr2.ladderElems(i).Y = lddr.ladderElems(i).Y - deltW*lddr.ladderElems(i).C*j;
    end
  end
