function [Ki, KF, Ko] = calcBilSS(Sys)
% calcBilSS(Sys) calculates the Bilinear State-Space vectors and matrix of a digital zpk model
% H1 that was obtained using [H1, KI, KF, KO] = calcSFG_DFltr(Kib, KFb, Kob, Kdb)
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
  sS = ss(Sys);
  Ki = sS.B; % an upper case first letter followed by a lower-case letter indicates a column vector
  KF = sS.A; % all upper case indicates a matrix
  N = size(KF,1);
  I = eye(N);
  Ko = sS.C*inv(KF + I);
  Ko = Ko.'; % all vectors are column vectors
