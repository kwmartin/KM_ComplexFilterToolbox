function [Fltr, SS] = cont2BlnrSS(Ki, Kf, Ko, Kd)
% cont2BlnrSS(Ki, Kf, Ko, Kd) converts matrices from continuous-time 
% prototype filter to matrices required for a discrete-time filter
% without delay free loops based on the bilinear transform
% It is used in a design procedure that has now been superseded
% by a much better procedure (see example: DLddrFltr_1_8_0.m)
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

  KO = Ko/2;
  N = size(Kf,1);
  I = eye(N);
  M1 = inv(I - Kf/2);
  M2 = I + Kf/2;
  KI = M1*Ki;
  KF = M1*M2;

  A = KF;
  B = KI;
  C = KO*(I + KF);
  D = Kd + KO*KI;
  SS = ss(A, B, C, D, 1);

  Fltr = zpk(SS);
  
  a = 1;
