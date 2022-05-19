function R = gdyR(z, pls)
%   R = gdyR(pls) calculates cos( alpha(y) ) based on Chebyschev
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

  N = length(pls);
  trm1 = 1; trm2 = 1;
  K = 1;
  for i = 1:N
      K = K*(pls(i)'/pls(i));
  end
  for i = 1:N
      trm1 = trm1.*(pls(i) + z)./(conj(pls(i)) - z);
      trm2 = trm2.*(conj(pls(i)) - z)./(pls(i) + z);
  end
  R = 0.5*(K.*trm1 + (1/K).*trm2);
  a=1;
