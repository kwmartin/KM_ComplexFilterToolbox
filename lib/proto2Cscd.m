function cscdFltr = proto2Cscd(H1, p, px, wp, ws, as, sclFctr, shftFctr)
%   cscdFltr = proto2Cscd(H1, p, px, wp, ws, as, sclFctr, shftFctr) returns final cascade filter
%   It undoes previous normalization used to better numerical accuracy
%
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

  rvrsScl = 1/sclFctr;

  cscdFltr = mkCscdFltr(H1, wp, rvrsScl); % main program for creating a cascade filter
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, rvrsScl); % unscales filter
  [p, px, wp, ws, as] = undistortSpecs(p, px, wp, ws, as); % undistorts specs (previously distorted for bilinear)
  [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, -shftFctr); % shifts specs back to original values

  %
  % Note: specs are not being returned; we calculate them in case we change our mind in the future
  %
  H3 = cscdFltr.fshftFltr(-shftFctr); % H3 is final cascade filter; see cascadeClass.m
