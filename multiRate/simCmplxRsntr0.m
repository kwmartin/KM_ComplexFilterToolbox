function [Xerr, Xo2] = simCmplxRsntr0(xin, rsntrs, G, Gfb)
%   [Xe, Xouts] = simCmplxRsntr0(xin, rsntrs, G, Gfb)
%   simulates a complex resonator in a loop
%   and uses weighted sums of FT outputs for better stopbands. Very similar
%   to simCmplxResonators2 (which is faster).
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
  npts = length(xin);
  Nchls = length(G);
  Xout = zeros(npts, Nchls);
  Xo2 = zeros(npts, 1);
  Xsum = zeros(npts, 1);
  Xerr = zeros(npts, 1);
  Xi = zeros(npts, 1);
  for i = 1:npts
    Xerr = 0;
    Xsum(i) = 0;
    Xo2(i) = 0;

    for k = 1:Nchls
      Xout(i, k) = rsntrs(k).getOut();
      Xsum(i) = Xsum(i) + Xout(i, k);
      Xo2(i) = Xo2(i) + G(k)*Xout(i, k);
    end

    Xerr(i) = xin(i) - Xsum(i);
    Xi(i) = Gfb*Xerr(i);

    for k = 1:Nchls
      rsntrs(k).updateState(Xi(i));
    end
    a = 1;
  end
  a=1;