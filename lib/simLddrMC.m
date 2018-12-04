function out1 = simLddrMC(lddr, xin, wp, delta_f, std, nmbRuns, ylim)
% function out1 = simLddr(TFs, xin, delta_f) simulates the ladder filter
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
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

  eshft = exp(j*2*pi*delta_f);
  npts = length(xin);
  out1 = zeros(npts, 1);
  out2 = zeros(npts, 1);

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

  out1 = simLddr(lddr, xin,  0);
  hndl = figure('Position',[800 100 600 600]);
  [ax1 ax2, f, ymRef] = plotRspns(out1, wp, 'b', ylim);
  errs = zeros(size(ymRef));
  hold(ax1, 'on');
  hold(ax2, 'on');

  for i=1:nmbRuns
    d1_0_ = d1_0*(1 + normrnd(0, std, 1));
    rMtrx = rndmMtrx(std, N);
    c_ = rMtrx*c;
    rMtrx = rndmMtrx(std, N);
    diag_mn_ = rMtrx*diag_mn;
    rMtrx = rndmMtrx(std, N);
    diag_dn_ = rMtrx*diag_dn;
    rMtrx = rndmMtrx(std, N);
    diag_up_ = rMtrx*diag_up;
    rMtrx = rndmMtrx(std, N);
    b1_ = rMtrx*b1;
    rMtrx = rndmMtrx(std, N);
    b2_ = rMtrx*b2;
    rMtrx = rndmMtrx(std, N);
    a_ = rMtrx*a;

    for i = 1:npts
      f = c_.*X;
      f(1) = f(1) + d1_0_*xin(i);
      Y = solveTriDiag( diag_mn_, diag_dn_, diag_up_, f, v, w_inv );
      out2(i) = Y(N);
      X = a_.*X + b1_.*[xin(i); Y(1:N-1)] + b2_.*[Y(2:N); 0];
      X = X.*eshft;
    end
    [ax1 ax2, f, ym] = plotRspns(out2, wp, 'r', ylim);
    errs = errs + (ym - ymRef).^2;
  end
  sumErrs = sqrt(sum(errs));
  display(sprintf('Monte-Carlo standard deviation of errors: %0.5g\n', ...
      sumErrs));
  pltMx = max(0.5*db(errs)) + 2;
  % plot_errs(f, 0.5*db(errs), 'b', [-0.5, 0.5, ylim(1), pltMx]);


