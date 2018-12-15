function out = simCscd(cscd, xin, fShft)
% function out = simCscd(cscd, xin, fShft) simulates the cscd filter
% cscd is a cascadeClass object
% xin is the input data, fShft is an optional frequency shift
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

  A = {};
  B = {};
  C = {};
  D = {};
  for i = 1:cscd.size
    sys = cscd.sctns(i).sys;
    [a b c d] = ssdata(sys);
    A{i} = a;
    B{i} = b;
    C{i} = c;
    D{i} = d;
  end

  xin = zeros(8192,1);
  xin(1) = 1;
  out = simBiquad(A, B, C, D , xin, fShft);
