%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [p, px, wp, ws, H3] = invrsTrnsfrmH(H1, p, px, wp, ws, sclFctr, shftFctr)
% shift specs to 0 and then scale wp to -1,1

  rvrsScl = 1/sclFctr;
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, rvrsScl);
  [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, -shftFctr);
  H2 = scaleFltr(H1, rvrsScl);
  H3 = freq_shift(H2, -shftFctr*j);
