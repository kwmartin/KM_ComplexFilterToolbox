function [Xfb, Xs, Xe, Xs1, X1o, X2o] = simResonators2(xin, k, G, X10, X20)
%   xout = simResonators2(xin, k) simulates a resonator in a loop 
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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
  N = length(k);
  npts = length(xin);

  Xin = zeros(npts, N);
  Xfb = zeros(npts, N);
  Xs = zeros(npts, N);
  Xe = zeros(npts, 1);
  Xs1 = zeros(npts, N);

  Xi1 = zeros(1, N);
  Xi2 = zeros(1, N);
  X1 = zeros(1, N);
  X2 = zeros(1, N);
  X1 = X10;
  X2 = X20;
  Xones = ones(1,N);
  for i = 1:npts
    X1o = X1;
    X2o = X2;
    Xi2 = k.*X1 + X2;
    Xfb(i, :) = 2.*X1 - k.*Xi2;
    if k(1) == 0
        Xi2(1) = 0;
        Xfb(i,1) = X1(1);
    end
    Xe(i) = xin(i) - sum(Xfb(i, :));
    Xi = G.*Xe(i).*Xones;
    Xi1 = Xi - k.*Xi2 + X1;
    Xs(i, :) = 2.*Xi2;
    X1 = Xi1;
    X2 = Xi2;
    Xs1(i,:) = Xs(i,:).*(Xe(i).*Xones);
    a=1;
  end

  a=1;