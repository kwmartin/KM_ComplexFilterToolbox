function Hz = trnsfrmY2z(Hy,wp,e_)
%   transforms a continuous-time model in the x domain
%   to the discrete-time z domain using a conformal transform
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

  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  xsq2z = @(xsq,wi)((2 + j.*wi(2) + xsq.*(-2 - j.*wi(1)))./(2 - j.*wi(2) - xsq.*(2 - j.*wi(1))));
  z1 = sortAbs(Hy.z{1});
  z2 = z1(1:2:end-1).^2;
  p1 = sortAbs(Hy.p{1});
  p2 = p1(1:2:end-1).^2;
  zz = xsq2z(z2,wp);
  pz = xsq2z(p2,wp);
  Hz = zpk(zz,pz,1,1);
  wpsbnd = 2*atan(wp./2); % wp is pre-distorted, this goes back to specifications
  g =1/(abs(freqresp(Hz,wpsbnd(1)))*sqrt(1.0 + e_^2));
  Hz.k = g*Hz.k;

  a=1;
