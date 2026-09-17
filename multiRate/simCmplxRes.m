function [Xout, Xerr, Xsen, deltw, w] = simCmplxRes(xin, rsntr, Gfb)
%   [Xe, Xouts] = simCmplxRes(xin, rsntr, Gfb)
%   simulates a singlecomplex resonator in a loop
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

  npts = length(xin);
  Xout = zeros(npts, 1);
  Xsen = zeros(npts, 1);
  Xerr = zeros(npts, 1);
  Xi = zeros(npts, 1);
  deltw = zeros(npts, 1);
  w = zeros(npts, 1);
  for i = 1:npts
    Xout(i) = rsntr.getOut();
    Xsen(i) = conj(Xout(i));

    Xerr(i) = xin(i) - Xout(i);
    Xi(i) = Gfb*Xerr(i);
    deltw(i) = Xsen(i)*Xerr(i);
    w(i) = rsntr.wi + 0.1*imag(deltw(i));
    rsntr.setWi(w(i));

    rsntr.updateState(Xi(i));
    a = 1;
  end
  a=1;