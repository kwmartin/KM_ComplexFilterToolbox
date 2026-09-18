%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [p, px, wp, ws, as, H4] = invrsTrnsfrmD(H1, p, px, wp, ws, as, sclFctr, shftFctr)
% shift specs to 0 and then scale wp to -1,1

  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  rvrsScl = 1/sclFctr;
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, rvrsScl);
  [p, px, wp, ws, as] = undistortSpecs(p, px, wp, ws, as);
  [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, -shftFctr);
  % The bilinear function in the Control toolbox does not work with complex
  % systems; however, the bilinear function in the signal processing toolbox
  % does

  % Extract zeros, poles, and k from the still-normalized analog prototype.
  % The reverse-scale (rvrsScl) is folded directly into bilinear's sample
  % rate rather than applied to H1 first via scaleFltr: bilinear's formula
  % z=(1+p'T/2)/(1-p'T/2) with p'=rvrsScl*p, T=1 is algebraically identical
  % to applying it to the unscaled p with fs=sclFctr (T=rvrsScl), so this
  % is mathematically exact, not an approximation -- it just skips
  % scaleFltr's zpk->ss->scale->ss->zpk round-trip and the eigendecomposition
  % of the rescaled A matrix, which measurably loses accuracy for
  % narrowband designs with tightly-clustered poles.
  [z p k] = zpkdata(H1, 'v');
  % Transform to discrete-time system using bilinear transform
  [zd pd kd] = bilinear(z,p,k,sclFctr);
  H3 = zpk(zd,pd,kd,1); % Make zero, pole system
  H3 = simpl(H3);

  H4 = freq_shiftd(H3, -shftFctr);
