function [H, Ki, KF, Ko, Kd] = calcSectionSS(z, p, gain)
%   calcBiquadSS(z, p, gain, type) calculates the State-Space
%   coefficients for a biquad. We expect to support most biquad transfer
%   functions, but have currently only done type == 'notch'
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

  nz = length(z);
  np = length(p);
  tol = 5e-5;

  if np == 2 && nz == 2 % Second order with transmission zero on jw axis
    if abs(real(z(1))) > tol || abs(real(z(2))) > tol
      error('Only jw axis zeros are curently handled')
    end
    k11 = 0;
    w0 = sqrt(p(1)*p(2));
    wz_sq = z(1)*z(2);
    k12 = -w0*j;
    k21 = w0*j;
    k22 = p(1)+p(2);
    ko0 = gain*k12*k21/wz_sq;
    k10 = gain*(k12 - ko0*k12);
    kd = ko0;
    k20 = ko0*k22;
    KF = [k11, -k12; k21, k22];
    Ki = [k10; k20];
    Ko = [0 1];
    Kd = [kd];
    H = ss(KF, Ki, Ko, Kd);
    a=1;
  end

  if np == 2 && nz == 0 % Second order without transmission zeros
    k11 = 0;
    w0 = sqrt(p(1)*p(2));
    k12 = -w0*j;
    k21 = w0*j;
    k22 = p(1)+p(2);
    k10 = gain*k12;
    kd = 0;
    k20 = 0;
    KF = [k11, -k12; k21, k22];
    Ki = [k10; k20];
    Ko = [0 1];
    Kd = 0;
    H = ss(KF, Ki, Ko, Kd);
    a=1;
  end

  if np == 1
    k11 = p(1);
    k10 = -gain*k11;
    if isempty(z)
        ko0 = 0;
    else
        ko0 = -k10/z(1);
    end
    KF = [k11];
    Ki = [k10 + ko0*k11];
    Ko = [1];
    Kd = [ko0];
    H = ss(KF, Ki, Ko.', Kd);
    a = 1;
  end