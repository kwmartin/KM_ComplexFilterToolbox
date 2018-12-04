function xout = simBiquad2(A_, B_, C_, D_, xin, delta_f)
%   xout = simBiquad2(A_, B_, C_, D_, xin, delta_f) runs input vector xin through
%   cascade filter having cell arrays A_, B_, C_, D_; delta_f is normally 1,
%   but can be a frequency shift of filters
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

  nmbSctns = size(A_, 2);
  xout = zeros(nmbSctns, npts);
  x = zeros(nmbSctns, npts);
  x1 = zeros(nmbSctns, npts);

  for k = 1:nmbSctns
    N = size(A_{k},1);
    X{k} = zeros(N,1);
    X1{k} = zeros(N,1);
  end
  for i = 1:npts
    x_in = xin(i);
    for k = 1:nmbSctns
      x(k, i) = C_{k}*X{k} + D_{k}*x_in;
      X1{k} = A_{k}*X{k} + B_{k}*x_in;
      X{k} = X1{k}*eshft;
      x_in = x(k, i);
    end
  end
  xout = x(k,:).';
