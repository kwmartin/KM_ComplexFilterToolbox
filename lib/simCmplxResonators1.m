function [Xfb, Xs, Xe, Y, Xp] = simCmplxResonators1(xin, e2jwp, G, X0)
%   [Xfb, Xs, Xe, Y, Xp] = simCmplxResonators1(xin, e2jwp, G, X0)
%    simulates a complex resonator in a loop 
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
  N = length(e2jwp);
  npts = length(xin);

  Xin = zeros(npts, N);
  Xfb = zeros(npts, N);
  Xs = zeros(npts, N);
  Xe = zeros(npts, 1);
  Xp = zeros(npts, N);

  Xi = zeros(1, N);
  X1 = zeros(1, N);
  X1 = X0.*conj(e2jwp);
  Xones = ones(1,N);
  for i = 1:npts
    Xfb(i, :) = X1.*e2jwp;
    Xe(i) = xin(i) - sum(Xfb(i, :));
    Xi = G.*Xe(i).*Xones;
    Xi1 = Xi + Xfb(i, :);
    X1 = Xi1;
    Xs(i,:) = -real(Xfb(i, :)).*imag(Xe(i).*Xones) + imag(Xfb(i, :)).*real(Xe(i).*Xones);
    Xp(i,:) = Xfb(i, :).*conj(Xfb(i, :));
    a=1;
  end
  Y = Xfb;
  a=1;