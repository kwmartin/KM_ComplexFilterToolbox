function [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as)
%   shift specs of digital filter to 0, then predistorts specs assuming a bilinear
%   transform will be used and then scale passband wp to -1,1
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
  shftFctr = -(wp(1) + wp(2))/2;
  [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, shftFctr);
  [p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs
  sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);
  a=1;
