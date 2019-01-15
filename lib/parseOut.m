function OutData = parseOut(nmbChnls)
% parses output of rdFltr.go into a matrix
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
  [Out delim] = importdata('/home/martin/Dropbox/go/src/github.com/kw_martin/tstYml/fltr.dat');
  N = size(Out, 1);
  OutData = zeros(N, nmbChnls);
  for i = 1:N
    C = textscan(Out{i},'(%f)');
    OutData(i,:) = C{1};
  end
  a=1;