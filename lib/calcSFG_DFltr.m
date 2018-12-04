function [Fltr, Ki, KF, Ko, Kd, SS] = calcSFG_DFltr(Ki, Kf, Ko, Kd)
% calcSFG_DFltr(Fltr, Ki, KF, Ko, Kd, SS) converts matrices from continuous-time 
% prototype filter to matrices required for a discrete-time filter
% without delay free loops based on the bilinear transform
% This approach works for designing digital filters, but it was found
% using Monte-Carlo simulations that the stop-bands were too sensitive
% so a different approach was developed that is much much less sensitive
% see: DLddrFltr_1_8_0.m for an example of the improved approach
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

  Ko = Ko/2;
  N = size(Kf,1);
  M1 = inv(eye(N) - Kf/2);
  M2 = eye(N) + Kf/2;
  Ki = M1*Ki;
  KF = M1*M2;

  for i = 1:N
    uCells{i} = sprintf('u%d', i);
    eCells{i} = sprintf('e%d', i);
    xCells{i} = sprintf('x%d', i);
    kfoCells{i} = sprintf('kfo%d', i);
    sCells{i} = sprintf('s%d', i);
  end

  for i =1:size(Ki, 2)
    xinCells{i} = sprintf('xin%d', i);
  end
  
  for i =1:size(Ko, 1)
    oCells{i} = sprintf('o%d', i);
    dCells{i} = sprintf('d%d', i);
    outCells{i} = sprintf('out%d', i);
  end
  
  Sm1 = sumblk('%e = %u + %kfo', eCells, uCells, kfoCells);
  Sm2 = sumblk('%s = %e + %x', sCells, eCells, xCells);
  Sm3 = sumblk('%out = %o + %d', outCells, oCells, dCells);

  TKi = tf(Ki);
  TKi.u = xinCells;
  TKi.y = uCells;

  TKF = tf(KF);
  TKF.u = xCells;
  TKF.y = kfoCells;

  TKo = tf(Ko);
  TKo.u = sCells;
  TKo.y = oCells;

  TKd = tf(Kd);
  TKd.u = xinCells;
  TKd.y = dCells;

  TF2 = {};
  for i = 1:N
    for j = 1:N
      if j == i
        Nm{j} = [0, 1];
        Dn{j} = [1];
      else
        Nm{j} = [0];
        Dn{j} = [1];
      end
    end
    TF1 = tf(Nm, Dn, 1, 'Variable','z^-1');
    TF2{i} = TF1;
    TF2{i}.u = eCells;
    TF2{i}.y = xCells{i};
  end

  TF2{N+1} = TKi;
  TF2{N+2} = TKF;
  TF2{N+3} = Sm1;
  TF2{N+4} = TKo;
  TF2{N+5} = Sm2;
  TF2{N+6} = TKd;
  TF2{N+7} = Sm3;
  outNm = outCells{size(Ko, 1)};

  warning('off','Control:combination:connect9')
  warning('off','Control:combination:connect10')
  SS = connect(TF2{:}, 'xin1', outNm);
  warning('on','Control:combination:connect9')
  warning('on','Control:combination:connect10')
  Fltr = zpk(SS);
  
  a = 1;
