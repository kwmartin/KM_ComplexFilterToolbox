function dispLddr(lddr)
% dispLddr(lddr) prints out the components of a ladder object from ladderClass
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
  size = lddr.size;
  for i=1:size
    elem = lddr.ladderElems(i);
      switch elem.type
        case 'SHL'
          disp(sprintf('i: %d: SHL: L: %0.7g, X: %0.7gj', i, elem.L, imag(elem.X)))
        case 'SHC'
          disp(sprintf('i: %d: SHC: C: %0.7g, Y: %0.7gj', i, elem.C, imag(elem.Y)))
        case 'SHX'
          disp(sprintf('i: %d: SHX: X: %0.7gj', i, imag(elem.X)))
        case 'SHY'
          disp(sprintf('i: %d: SHY: Y: %0.7gj', i, imag(elem.Y)))
        case 'SRL'
          disp(sprintf('i: %d: SRL: L: %0.7g, X: %0.7gj', i, elem.L, imag(elem.X)))
        case 'SRC'
          disp(sprintf('i: %d: SRC: C: %0.7g, Y: %0.7gj', i, elem.C, imag(elem.Y)))
        case 'SRX'
          disp(sprintf('i: %d: SRX: X: %0.7gj', i, imag(elem.X)))
        case 'SRY'
          disp(sprintf('i: %d: SRY: Y: %0.7gj', i, imag(elem.Y)))
        case 'SHLC'
          disp(sprintf('i: %d: SHLC: L: %0.7g, X: %0.7gj, C: %0.7g, Y: %0.7gj', ...
            i, elem.L, imag(elem.X), elem.C, imag(elem.Y)))
        case 'SRLC'
          disp(sprintf('i: %d: SRLC: L: %0.7g, X: %0.7gj, C: %0.7g, Y: %0.7gj', ...
            i, elem.L, imag(elem.X), elem.C, imag(elem.Y)))
        end
    end
  disp(sprintf('R1: %0.7g, R2: %0.7g', lddr.R1, lddr.R2))
