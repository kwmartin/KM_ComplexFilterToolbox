function xout = simCscdFltrMc(cscdFltr, xin, std, fShft)
%   xout = simCscdFltrMc(cscdFltr, xin, std, fShft) simulates a perturbed cascade filter
%   as part of a Monte Carlo simulation; it is called from runMCCscd2(). It uses the cascade
%   object cscdFlter.sim.
%
%   11/29/08: this function has been deprecated by runMcCscd.m, At the
%   least, it should reset cscdFltr to its original value and not leave
%   it perturbed.
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

  for i = 1:cscdFltr.size
    sys1 = cscdFltr.sctns(i).sys;
    [a b c d T] = ssdata(sys1);
    N = size(a, 1);
    rMtrx = rndmMtrx(std, N);
    a2 = rMtrx*a;
    rMtrx = rndmMtrx(std, N);
    b2 = rMtrx*b;
    rMtrx = rndmMtrx(std, N);
    c2 = c*rMtrx;
    rMtrx = rndmMtrx(std, 1);
    d2 = rMtrx*d;
    sys2 = ss(a2, b2, c2, d2, T);
    sys3 = zpk(sys2);
    cscdFltr.sctns(i).setSys(sys3);
  end
  cscdFltr.getSystem(); % this updates the overall cascade filter sys
  xout = cscdFltr.sim(xin, fShft);
  a=1;