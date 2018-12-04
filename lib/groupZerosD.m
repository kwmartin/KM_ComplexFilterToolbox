%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [z3 p3] = groupZerosD(H, wp)
% groupZeros() is used to pair the zeros of a discrete-time transfer function with poles
%

  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  tol = 1e-4;
  grps = {};
  [z,p,k] = zpkdata(H, 'v');
  nz = length(z);
  np = length(p);

  % sort poles and zeros in ascending order based on angles

  z2 = sortArry(@(x) angle(x), z);
  p2 = sortArry(@(x) angle(x), p);

  % group zeros to closest poles going from zeros closest to midWp
  i = 1;
  midWp = 2*pi*(wp(1) + wp(2))/2;
  while length(z2) ~=0
    [z2 zr indx] = chooseX(@(x) (abs(angle(z2) - midWp)), z2);
    [p2 pl indx] = chooseX(@(x) (abs(angle(p2) - angle(zr))), p2);
    grps{i} = {zr, pl};
    z3(i) = zr;
    p3(i) = pl;
    i = i+1;
  end

  % assuming bilinear transform, the number of zeros equals the number of poles
  a=1;
