function out = simLddr(lddr, xin, delta_f)
% function out = simLddr(TFs, xin, delta_f) simulates the ladder filter
% lddr is a ladderClass object
% xin is the input data, delta_f is an optional frequency shift
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
  out = zeros(npts, 1);

  TFs = calcLddrSSFLtrs(lddr);
  N = size(TFs,2);
  X = zeros(N, 1);
  f = zeros(N, 1);
  [diag_mn, diag_dn, diag_up, c, v, w_inv] = initOutVctrs(TFs);

  for i=1:N
    b1(i) = TFs{i}.B(1);
  end
  b1 = b1.';
  for i=1:N-1
    b2(i) = TFs{i}.B(2);
  end
  b2(N) = 0;
  b2 = b2.';
  for i=1:N
    a(i) = TFs{i}.A;
  end
  a = a.';
  d1_0 = TFs{1}.D(1);

  for i = 1:npts
    f = c.*X;
    f(1) = f(1) + d1_0*xin(i);
    Y = solveTriDiag( diag_mn, diag_dn, diag_up, f, v, w_inv );
    out(i) = Y(N);
    X = a.*X + b1.*[xin(i); Y(1:N-1)] + b2.*[Y(2:N); 0];
    X = X.*eshft;
  end

