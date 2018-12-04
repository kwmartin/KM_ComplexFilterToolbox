function [p, px, wp, ws, as, H4] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr)
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

  % Unscale continous-time filter
  H2 = scaleFltr(H1, rvrsScl);

  % The bilinear function in the Control toolbox does not work with complex
  % systems; however, the bilinear function in the signal processing toolbox
  % works for complex transfer functions

  % Extract zeros, poles, and k
  [z p k] = zpkdata(H2, 'v');
  % Transform to discrete-time system using bilinear transform
  [zd pd kd] = bilinear(z,p,k,1);

  % Make control-system zpk model
  H3 = zpk(zd,pd,kd,1);
  % Clean model
  H3 = simpl(H3);
  % Frequency shift back to desired passband frequencies
  H4 = freq_shiftd(H3, -shftFctr);
