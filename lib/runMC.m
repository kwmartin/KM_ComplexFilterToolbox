function runMC(KI, KF, KO, wp, minY, std, fShft, nmbRuns)
%   runMC(KI, KF, KO, wp, minY, std, fShft, nmbRuns) run Monte Carlo simulations
%   on ladder filter simulations; this has been deprecated as of 11/25/2018 and replaced
%   with a much superior digital ladder simulation filter
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

  xin = zeros(8192,1);
  xin(1) = 1;
  freq_shtf = fShft;
  xout = simFltr(KI, KF, KO, xin, freq_shtf);
  hndl(6) = figure('Position',[800 100 600 600]);
  [ax1 ax2] = plotRspns(xout, wp + freq_shtf, 'b', [minY, 2]);
  %[f, ndB, dB, ym, ya] = nfft2(xout,'b', -120, 2);

  hold(ax1, 'on');
  hold(ax2, 'on');
  N = size(KF, 1);
  for i=1:nmbRuns
    rMtrx = rndmMtrx(std, N);
    KI2 = rMtrx*KI;
    rMtrx = rndmMtrx(std, N);
    KF2 = rMtrx*KF;
    rMtrx = rndmMtrx(std, N);
    KO2 = rMtrx*KO;
    xout2 = simFltr(KI2, KF2, KO2, xin, freq_shtf);
    [ax1 ax2] = plotRspns(xout2, wp + freq_shtf, 'm', [minY, 2]);
    %[f, ndB, dB, ym, ya] = nfft2(xout2,'r', minY, 2);
  end

