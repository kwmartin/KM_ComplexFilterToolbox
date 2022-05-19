function [Xfb, Xs, Xe, Y, Xp] = simCmplxResonators4(xin, e2jwp, G, X0)
%   xout = simCmplxResonators4(xin, e2jwp, G, X0)
%   simulates a complex resonator in a loop
%   and uses weighted sums of FT outputs for better stopbands. Very similar
%   to simCmplxResonators2 (which is faster), except weighting multiplications
%   take place inside loop.
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
  Y = zeros(npts,N/4);
  Xs = zeros(npts, N);
  Xe = zeros(npts, 1);
  Xp = zeros(npts, N);

  Xi = zeros(1, N);
  X1 = zeros(1, N);
  X1 = X0.*conj(e2jwp);
  Xones = ones(1,N);
  Coeffs = [1; -0.97195983; 0.70710678; -0.23514695];
  for i = 1:npts
    X1o = X1;
    Xfb(i, :) = X1.*e2jwp;
    Xe(i) = xin(i) - sum(Xfb(i, :));
    Xi = G.*Xe(i).*Xones;
    Xi1 = Xi + Xfb(i, :);
    X1 = Xi1;
    Xs(i,:) = -real(Xfb(i, :)).*imag(Xe(i).*Xones) + imag(Xfb(i, :)).*real(Xe(i).*Xones);
    Xp(i,:) = Xfb(i, :).*conj(Xfb(i, :));
    Xss = [Xfb(i,1) (Xfb(i,2)+Xfb(i,N)) (Xfb(i,3)+Xfb(i,N-1)) (Xfb(i,4)+Xfb(i,N-2))];
    Y(i, 1) = Xss*Coeffs;
    for k=2:N/4
        Xss = [Xfb(i,k*4-3) (Xfb(i,k*4-4)+Xfb(i,k*4-2)) (Xfb(i,k*4-5)+Xfb(i,k*4-1)) ...
            (Xfb(i,k*4-6)+Xfb(i,k*4))];
        Y(i, k) = -j*(j^k)*Xss*Coeffs;
    end
    a=1;
  end

  a=1;