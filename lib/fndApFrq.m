function w = fndApFrq(H, ap)
%   w = fndApFrq(H, ap) finds the frequency that has passband gain ap
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
  w = 1;
  ep = -ap*log(10)/20; % desired loss in nepers
  for i = 1:10
    [lgH, phH, gdH, dLdW, dTdW] = AnlzH(H, w);
    w = w - (lgH - ep)./dLdW;
  end
