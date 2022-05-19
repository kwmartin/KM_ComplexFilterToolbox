function Hz = y2zSb(Hy,wp)
%   Hz = y2zSb(Hy,wp) transforms a continuous-time model in the y domain
%   to the discrete-time z domain using a conformal transform. It does
%   not use a square root function. This transform is intended to improve
%   the numerical accuracy when designing equi-ripple group-delay filters.
%   It is intended for stop-band transforms.
%
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

  y2z = @(y,wi)((2*j - wi(2) + y.*(2 + j*wi(1)))./(2*j + wi(2) + y.*(2 - j*wi(1))));
  zz = y2z(-Hy.z{1},wp);
  pz = y2z(-Hy.p{1},wp);
  Hz = zpk(zz,pz,1,1);
  a=1;
