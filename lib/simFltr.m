function xout = simFltr(Ki, Kf, Ko, xin, delta_f)
%   simFltr(Ki, Kf, Ko, xin) runs input vector xin through
%   digital filter having State-Space system defined by Ki, Kf, and Ko
%   deprecated as of 11/25/2018
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
  eshft = exp(j*2*pi*delta_f);
  npts = length(xin);
  xout = zeros(npts, 1);
  N = size(Kf,1);
  X = zeros(N, 1);
  KoVctr = Ko(N,:);
  for i = 1:npts
    X1 = Ki*xin(i) + Kf*X;
    xout(i) = KoVctr*(X1 + X);
    X = X1*eshft;
  end