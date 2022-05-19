function Hx = z2xSb(Hz,wp)
%   Hx = z2xSb(Hz,wp) transforms a discrete-time model in the z domain
%   to the continuous-time x domain using a conformal transform. It does
%   not use a square root function. This transform is intended to improve
%   the numerical accuracy when designing equi-ripple group-delay filters
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

  %The only difference from z2x is the sign of the next function
  z2y = @(z,wi)(j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
  zx = z2y(Hz.z{1},wp);
  px = z2y(Hz.p{1},wp);
  s = tf('s');
  nz = length(zx);
  num = zpk([],[],1);
  for i=1:nz
      num = num*(s - zx(i));
  end
  np = length(px);
  den = zpk([],[],1);
  for i=1:np
      den = den*(s - px(i));
  end
  Hx = simpl(num/den);
  a=1;
