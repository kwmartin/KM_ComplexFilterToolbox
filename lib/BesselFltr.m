function H = BesselFltr(n)
%   H = BesselFltr(n) finds a Bessel Lowpass Filter of order n
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
  e2 = [1];
  e1 = [1 1];
  for i = 2:n
    en = [e2 0 0] + (2*i - 1)*[0 e1];
    e2 = e1;
    e1 = en;
  end
  TF = tf([en(n+1)], en);
  H = zpk(TF);
  a = 1;
