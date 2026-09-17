function [Xout, Xerr, Xsen, deltw, w] = simCmplxResons(xin, rsntrs, Gfb)
%   [Xe, Xouts] = simCmplxResons(xin, rsntrs, Gfb)
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

  N = length(rsntrs);
  npts = length(xin);
  deltw = zeros(npts, N);
  Xsen = zeros(npts, N);
  w = zeros(npts, N);
  Xout = zeros(npts, N);
  Xsum = zeros(npts, 1);
  Xerr = zeros(npts, 1);
  Xi = zeros(npts, 1);

  for i = 1:npts
    Xsum(i) = 0.0;
    for k = 1:N
      Xout(i, k) = rsntrs(k).getOut();
      Xsen(i, k) = conj(Xout(i, k));
      Xsum(i) = Xsum(i) + Xout(i, k);
    end

    Xerr(i) = xin(i) - Xsum(i);
    Xi(i) = Gfb*Xerr(i);

    for k = 1:N
      deltw(i, k) = Xsen(i, k)*Xerr(i);
      w(i, k) = rsntrs(k).wi + 0.001*imag(deltw(i, k));
      rsntrs(k).setWi(w(i, k));
      rsntrs(k).updateState(Xi(i));
    end
    a = 1;
  end
  a=1;