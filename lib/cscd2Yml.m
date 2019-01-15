function cscd2Yml(cscdFltr, fileNm) % output cascade filter to yaml file
%   cscd2Yml(cscdFltr, fileNm) makes a yaml file of the poles and zeros
%   of a cascade filer.
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
  path(path, '../lib/yamlmatlab');
  c2str = @(c)sprintf('%.8f + %.8fi ', c, c/1i);
  
  nmbSctns = int8(cscdFltr.size);
  cscdStrct(1).nmbsections = nmbSctns;
  cscdStrct.sections = cell(1,nmbSctns);
  for i = 1:nmbSctns
    sys = cscdFltr.sctns(i).sys;
    [a b c d] = ssdata(sys);
    if size(a, 1) == 2
      cscdStrct.sections{i}.a11 = c2str(a(1,1));
      cscdStrct.sections{i}.a12 = c2str(a(1,2));
      cscdStrct.sections{i}.a21 = c2str(a(2,1));
      cscdStrct.sections{i}.a22 = c2str(a(2,2));
      cscdStrct.sections{i}.b1 = c2str(b(1));
      cscdStrct.sections{i}.b2 = c2str(b(2));
      cscdStrct.sections{i}.c1 = c2str(c(1));
      cscdStrct.sections{i}.c2 = c2str(c(2));
      cscdStrct.sections{i}.d = c2str(d);
    else
      cscdStrct.sections{i}.a = c2str(a(1,1));
      cscdStrct.sections{i}.b = c2str(b(1));
      cscdStrct.sections{i}.c = c2str(c(1));
      cscdStrct.sections{i}.d = c2str(d);
    end
  end

  waitfor(yaml.WriteYaml(fileNm, cscdStrct));
  a = 1;
