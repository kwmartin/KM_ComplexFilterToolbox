function runMcCscd(cscdFltr, wp, std, fShft, nmbRuns, ylim)
% runMcCscd(cscdFltr, wp, std, fShft, nmbRuns, ylim)
% run nmbRuns and plot FFTs of impulse responses of cascade filter
% having randomly perturbed matrices. cscdFltr is object of cascadeClass,
% std is standard deviation of perturbations, fShft is an optional
% frequency shift of filters, and ylim is limits on y of plots
% A slower but cleaner alternative is runMcCscd2() that use the
% cascadeClass.sim() function
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

  A_ = {};
  B_ = {};
  C_ = {};
  D_ = {};
  for i = 1:cscdFltr.size
    sys = cscdFltr.sctns(i).sys;
    [a b c d] = ssdata(sys);
    A_{i} = a;
    B_{i} = b;
    C_{i} = c;
    D_{i} = d;
  end

  xin = zeros(8192,1);
  xin(1) = 1;
  freq_shtf = fShft;
  xout = simBiquad(A_, B_, C_, D_ , xin, freq_shtf);

  hndl(6) = figure('Position',[800 100 600 600]);
  [ax1 ax2, f, ymRef] = plotRspns(xout, wp + freq_shtf, 'b', ylim);
  errs = zeros(size(ymRef));
  %[f, ndB, dB, ym, ya] = nfft2(xout,'b', -120, 2);

  hold(ax1, 'on');
  hold(ax2, 'on');
  for i=1:nmbRuns
    for i = 1:size(A_, 2)
      N = size(A_{i}, 1);
      rMtrx = rndmMtrx(std, N);
      A_2{i} = rMtrx*A_{i};
      rMtrx = rndmMtrx(std, N);
      B_2{i} = rMtrx*B_{i};
      rMtrx = rndmMtrx(std, N);
      C_2{i} = C_{i}*rMtrx;
      rMtrx = rndmMtrx(std, 1);
      D_2{i} = rMtrx*D_{i};
    end

    xout2 = simBiquad(A_2, B_2, C_2, D_2, xin, freq_shtf);
    [ax1 ax2, f, ym] = plotRspns(xout2, wp + freq_shtf, 'm', ylim);
    errs = errs + (ym - ymRef).^2;
    %[f, ndB, dB, ym, ya] = nfft2(xout2,'r', minY, 2);
    a = 1;
  end
  sumErrs = sqrt(sum(errs));
  display(sprintf('Monte-Carlo standard deviation of errors: %0.5g\n', ...
      sumErrs));
  pltMx = max(0.5*db(errs)) + 2;
  % plot_errs(f, 0.5*db(errs), 'b', [-0.5, 0.5, ylim(1), pltMx]);

