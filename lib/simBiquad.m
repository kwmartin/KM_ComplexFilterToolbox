function xout = simBiquad(A_, B_, C_, D_, xin, delta_f)
%   xout = simBiquad(A_, B_, C_, D_, xin, delta_f) runs input vector xin through
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
  for k = 1:nmbSctns
    a = A_{k};
    b = B_{k};
    c = C_{k};
    d = D_{k};

    N = size(a, 1);
    X = zeros(N, 1);

    for i = 1:npts
      xout(i) = c*X + d*xin(i);
      X1 = a*X + b.*xin(i);
      X = X1*eshft;
    end
    xin = xout;
  end
