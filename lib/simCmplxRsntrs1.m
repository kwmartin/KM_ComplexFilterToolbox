function [Xe, Xo2] = simCmplxRsntrs1(xin, rsntrs, G, Gis)
%   xout = simCmplxRsntrs1(xin, e2jwp, G, X0)
%   simulates a complex resonator in a loop
%   and uses weighted sums of FT outputs for better stopbands. Very similar
%   to simCmplxResonators2 (which is faster), except weighting multiplications
%   take place inside loop.
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

  N = length(rsntrs);
  xsts = zeros(1, N);
  npts = length(xin);
  Xo2 = zeros(npts, 1);
  for i = 1:npts
    [xi, xe, xo, xsts, xo2] = updateCmplxXi(xin(i), G, rsntrs, Gis);
    Xe(i) = xe;
    Xo2(i) = xo2;
    for j = 1:N
      rsntrs(j).updateState(xi);
    end
    a = 1;
  end

  a=1;