function [ax1, ax2] = plotHx(Hx,e_, ymin)
%   [Ax1, Ax2] = plotHx(Hx,e_, ymin) plots the passband and stopbands
%   in the transformed x Domain
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
  Ap = 10*log10(1 + e_^2);
  fx = (0:1e-4:10);
  hndl = figure('Position',[800 100 600 600]);
  hp = 20*log_rsps(Hx,j*fx) - Ap;
  ax1 = subplot(2,1,1);
  plot(fx, hp, 'r', 'LineWidth',2);
  title('Passband Response on Imaginary Axis');
  ylabel('dB');
  xlabel('Frequency (rad.)');
  axis([0 10 -Ap*1.1 0.025])

  ax2 = subplot(2,1,2);
  hr = 20*log_rsps(Hx,fx) - Ap;
  plot(fx, hr, 'r', 'LineWidth',2);
  title('Stopband Response on Real Axis');
  ylabel('dB');
  xlabel('Frequency (rad.)');
  % ymin = mean(hr) - 20;
  axis([0 10 ymin 2])
  a=1;
