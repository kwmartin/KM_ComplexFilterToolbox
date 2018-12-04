function [z11 z12] = mkXsSnglEnd_drep(H,ShntFirst)
% Find z11 and z12 of single-ended filter that has
% transfer function H. ShntFirst is a 1 if the first
% component is shunt
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

  tol = 2e-6;

  [P, E, ke] = zpkdata(H, 'v');

  Epl = polyClass(E, 1);

  imagRoots = true;
  [Eev, Eod] = getEvnOddPly(Epl);

  zev = Eev.rts;
  zod = Eod.rts;
  if ShntFirst sgn = -1; else sgn = 1; end
  if sgn*(Eev.N) > sgn*(Eod.N)
    z11 = zpk(zev, zod, Eev.K/Eod.K);
    z12 = zpk(P, zod, ke/Eod.K);
  else
    z11 = zpk(zod, zev, Eod.K/Eev.K);
    z12 = zpk(P, zev, ke/Eev.K);
  end
  imagRoots = false;

  H2 = zpk(z12/(tf(z11) + 1)); % for checking validity
end