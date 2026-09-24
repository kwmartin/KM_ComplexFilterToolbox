function [p, px, wp, ws, as, H4] = cont2Digital_scld(H1, p, px, wp, ws, as, sclFctr, shftFctr)
%   [_scld copy of cont2Digital.m - simpl tolerance scaled to the passband width; see ScldGD.md section 10]
% [p, px, wp, ws, as, H4] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr) Design discrete TF
% Is used to realize digital filter after an analog prototype has been designed
% It is assumed the analog prototype has been realized between -1 and 1 rad.
% The prototype is unscaled, the bilinear transform is applied, a zpk model is made
% and the model is shifted back to the desired frequency band.The poles, stop-band and
% pass-band frequencies of the final filter are returned.
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

  % Reverse specs
  rvrsScl = 1/sclFctr;
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, rvrsScl);
  [p, px, wp, ws, as] = undistortSpecs(p, px, wp, ws, as);
  [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, -shftFctr);

  % The bilinear function in the Control toolbox does not work with complex
  % systems; however, the bilinear function in the signal processing toolbox
  % works for complex transfer functions

  % Extract zeros, poles, and k from the still-normalized analog prototype.
  % The reverse-scale (rvrsScl) is folded directly into bilinear's sample
  % rate rather than applied to H1 first via scaleFltr: bilinear's formula
  % z=(1+p'T/2)/(1-p'T/2) with p'=rvrsScl*p, T=1 is algebraically identical
  % to applying it to the unscaled p with fs=sclFctr (T=rvrsScl), so this
  % is mathematically exact, not an approximation -- it just skips
  % scaleFltr's zpk->ss->scale->ss->zpk round-trip and the eigendecomposition
  % of the rescaled A matrix, which measurably loses accuracy for
  % narrowband designs with tightly-clustered poles.
  [z p_ k] = zpkdata(H1, 'v');
  % Transform to discrete-time system using bilinear transform
  [zd pd kd] = bilinear(z,p_,k,sclFctr);
  kd = real(kd); % bilinear has kd with a small complex part; looks like a bug

  % Make control-system zpk model
  H3 = zpk(zd,pd,kd,1);
  % Clean model
  % simpl's default tolerance is an absolute 1e-6: roots with a smaller
  % imaginary part are made real. For passbands narrower than about 1e-6
  % cycles the pole pairs' imaginary parts are below that, so they were
  % collapsed onto the real axis. Scale the tolerance with the band; it
  % equals the old 1e-6 for bands wider than about 1.6e-4 cycles.
  H3 = simpl(H3, min(1e-6, 1e-3*2*pi*(wp(2) - wp(1))));
  % Frequency shift back to desired passband frequencies
  H4 = freq_shiftd(H3, -shftFctr);
