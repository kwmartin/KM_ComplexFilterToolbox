function [Zin] = mkZin(E, F)
% E and F are vectors containing complex roots
% based on Fedtkeller's equations
% Zin is the input impedance of an LC filter
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
  global imagRoots;
  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  if nargin < 2
      termRight =  1;
  end

  tol = 1e-7;

  Epl = polyClass(E, 1);
  Fpl = polyClass(F, 1);

  Numpl = Epl - Fpl;
  Denpl = Epl + Fpl;

  Zin = zpk(Numpl.rts, Denpl.rts, Numpl.K/Denpl.K);
  Zin = simpl(Zin, tol);
  [Ks Pls Rem] = getRes(Zin);
  if abs(min(Ks)) < 1e-5
      disp('Filter Design is Ill-Conditioned')
  end

end