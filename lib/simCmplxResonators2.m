function [Xfb, Xs, Xe, Y, Yp] = simCmplxResonators2(xin, e2jwp, G, X0)
%   xout = simResonators(xin, k) simulates a complex resonator in a loop
%   and uses weighted sums of FT outputs for better stopbands. Very similar
%   to simCmplxResonators3 (which is slower), except weighting multiplications
%   take place outside loop.
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

  Xfb = zeros(npts, N);
  Xtst = zeros(npts, N);
  Xs = zeros(npts, N);
  Xe = zeros(npts, 1);
  % Yp = zeros(npts, N);

  Xi = zeros(1, N);
  X1 = zeros(1, N);
  X1 = X0.*conj(e2jwp);
  Xones = ones(1,N);
  Ks = [-0.23514695; 0.70710678; -0.97195983; 1.0; ...
      -0.97195983; 0.70710678; -0.23514695];
  A = zeros(N,N/4);
  A(2:8,2) = Ks;
  A(:,1) = circshift(A(:,2),-4);
  for i = 3:N/4
      A(:,i) = circshift(A(:,i-1),4);
  end
  jvct = -j*(j.^(1:N/4));
  diagj = diag(jvct);
  A = A*diagj;
  for i = 1:npts
    Xfb(i, :) = X1.*e2jwp;
    Xtst(i,:) = X1;
    Xe(i) = xin(i) - sum(Xfb(i, :));
    Xi = G.*Xe(i).*Xones;
    Xi1 = Xi + Xfb(i, :);
    X1 = Xi1;
    Xs(i,:) = -real(Xfb(i, :)).*imag(Xe(i).*Xones) + imag(Xfb(i, :)).*real(Xe(i).*Xones);
    %Yp(i,:) = Xfb(i, :).*conj(Xfb(i, :));
    a=1;
  end

  Y = Xfb*A;
  Yp = Y.*conj(Y);
  a=1;