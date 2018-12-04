function isEqual = chckEqlOrdr(ply, fun)
% isEqual = chckEqlOrdr(ply, fun) checks if a polyClass objest is identical to fun
% It's used to possibly terminate finding roots of a function early when
% the fun is itself a polynomial having less roots than expected.
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
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

if ply.N < 2
  isEqual = 0;
  return
end
tol = 1e-6;
rts = ply.rts;
N = ply.N;
rts1 = rts(1:N-1);
rts2 = rts(2:N);
evalPts = (rts1 + rts2)/2;
evalPly = ply.peval(evalPts);
evalFun = fun(evalPts);
div = evalPly./evalFun;
isEqual = range(abs(div))  < tol;