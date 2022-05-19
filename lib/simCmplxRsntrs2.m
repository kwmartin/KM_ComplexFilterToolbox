function [Xe, Xouts] = simCmplxRsntrs2(xin, Xs, Xos, G, Go)
% function [Xe, Xo2] = simCmplxRsntrs1(xin, rsntrs, G, Gis)
%   xout = simCmplxRsntrs2(xin, e2jwp, G, X0)
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

  trnc = @(val, d) (fix(val*2^d) + rand())/2^d;

  Ns = length(Xs);
  Ng = length(Go);
  Xpntr = zeros(Ng);
  j = 1;
  wp = [];
  for i = 1:Ns
    wp(i) = 2*pi*(i - 1)/Ns;
    % rsntrs(i) = cmplxRsntrClass(wp(i), Xs(i), Ns);
    rsntrs(i) = cmplxRsntrClass(wp(i), 0, Ns);
    if Xs(i) ~= 0
      Xpntr(i) = j;
      j = j+1;
    end
  end

  N = length(rsntrs);
  xsts = zeros(1, N);
  npts = length(xin);
  Nchls = length(Xos);
  Xouts = zeros(npts, Nchls);
  Xo2 = zeros(npts, 1);
  Xe = zeros(npts, 1);
  Xi = zeros(npts, 1);
  for i = 1:npts
    xin2 = trnc(xin(i), 12);
    [xi, xe, xo] = updateCmplxXi2(xin(i), G, rsntrs);
    Xe(i) = xe;

    for j = 1:Nchls
      ich = Xos(j);
      if ich == 0
          continue;
      end
      k = ich - (Ng + 1)/2 + 2;
      p = ich + (Ng + 1)/2;
      f = 1;
      Xouts(i,j) = 0;
      for m = k:p
        Xouts(i,j) = Xouts(i,j) + (rsntrs(m).Xo) * Go(f);
        f = f+1;
      end
    end
    
    Xi(i) = xi;
    for j = 1:N
      rsntrs(j).updateState(xi);
    end

    a = 1;
  end

  a=1;