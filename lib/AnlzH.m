function [lgH, phH, gdH, dLdW, dTdW] = AnlzH(H, w)
%   [lgH, phH, gdH, dHdW] = AnlzH(H, w) analyzs H and returns
%   the ln(abs(H)) (nepers), phH (radians), gdH (group delay in s),
%   and d(abs(H))/dw at frequency or frequencis specified in w (in radians)
%
%   Toolbox for the Dsign of Complex Filters
%   Copyright (C) 2018  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNsS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenss/>.
%
  [z, p, k] = zpkdata(H, 'vector');
  npts = length(w);
  onesVctr = ones(size(w));
  np = length(p);
  nz = length(z);
  derivSum = zeros(size(w));
  logSum = zeros(size(w));
  ddrvSum = zeros(size(w));
  s = j.*w;
  for l = 1:nz
      logSum = logSum + log((s - z(l)));
      derivSum = derivSum + 1./(s - z(l)*onesVctr);
      ddrvSum = ddrvSum + 1./((s - z(l)*onesVctr).^2);
  end
  for l = 1:np
      logSum = logSum - log((s - p(l)));
      derivSum = derivSum - 1./(s - p(l)*onesVctr);
      ddrvSum = ddrvSum - 1./((s - p(l)*onesVctr).^2);
  end
  phH = imag(logSum);
  lgH = log(k) + real(logSum);
  gdH = -real(derivSum); % because we didn't multiply by j in finding first order derivatives
  dLdW = -imag(derivSum);
  dTdW = -imag(ddrvSum);
