function Xout2 = simFltrBnk(A, B, C, D, xin, delta_f)
%   xout = simBiquad(A, B, C, D, xin, delta_f) runs input vector xin through
%   cascade filter having cell arrays A, B, C, D; delta_f is normally 1,
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
  N = 1/delta_f;
  wshft = j*2*pi*delta_f;
  eshft = exp(wshft);
  ex = -N/2 + 1:1:N/2;
  wshft = eshft.^ex;

  npts = length(xin);

  nmbSctns = size(A, 2);
  Xin = zeros(npts, N);
  Xout = zeros(npts, N);

  Xi1 = zeros(nmbSctns, N);
  Xi2 = zeros(nmbSctns, N);
  X1 = zeros(nmbSctns, N);
  X2 = zeros(nmbSctns, N);

  for i = 1:N
    Xin(:,i) = xin;
  end

  for k = 1:nmbSctns
    a = A{k};
    b = B{k};
    c = C{k};
    d = D{k};

    if size(a, 1) == 2
      for i = 1:npts
        Xout(i, :) = c(1).*X1(k,:) + c(2).*X2(k,:) + d*Xin(i, :);
        Xi1(k,:) = a(1,1).*X1(k,:) + a(1,2).*X2(k,:) + b(1).*Xin(i, :);
        Xi2(k,:) = a(2,1).*X1(k,:) + a(2,2).*X2(k,:) + b(2).*Xin(i, :);
        X1(k,:) = Xi1(k,:).*wshft;
        X2(k,:) = Xi2(k,:).*wshft;
      end
    else
      for i = 1:npts
        Xout(i, :) = c(1).*X1(k,:) + d*Xin(i, :);
        Xi1(k,:) = a(1,1).*X1(k,:) + b(1).*Xin(i, :);
        X1(k,:) = Xi1(k,:).*wshft;
      end
    end

    for i = 1:N
      Xin(:,i) = Xout(:, i);
    end
  end

  jMatrix = diag((j).^ex);
  Xout2 = Xout*jMatrix;

  a=1;