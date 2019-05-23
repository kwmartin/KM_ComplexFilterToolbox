function H2 = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type)
% H2 = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type) design a discrete-time transfer function
% Design a digital transfer function from specs, p: moveable poles, px: fixed poles,
% ni: number of fixed poles at infinity, wp: pass-band edge frequencies, ws: stop-band
% frequencies corresponding to as: stop-band attenuations at ws frequencies, only differences
% are material, and type: either "montonic" or "ellicptic"
% Do design on freq. shifted filter scaled to -+1, after the design is completed,
% the transfer function is shifted back to the originally specified frequencies.
% The transfer function returned is a zpk system object. As of 11/2018 this is 
% best top level for designing digital transfer fucntions using the bilinear transform.
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

  [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as);

  ONE_STP = 0;
  if strcmp(type, 'monotonic') || strcmp(type, 'elliptic')
    [H1, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,type);
  elseif strcmp(type, 'bessel')
    Ordr = 11;
    % Ap = -Ap;
    H1 = bessel_filt(Ordr, wp, Ap);
  elseif strcmp(type, 'equiGD')
    Ordr = 11;
    [H1 T0] = LinPhFltr(Ordr, 0.01, Ap);
  elseif strcmp(type, 'equiGDLsPls')
    Ordr = 11;
    H1 = LinPh_LssPls(Ordr, 0.01, Ap, 3);
  end
  % plot_crsps(H4,wp,ws,'b',[-10 10 -100 1]);
  % plot_am_ph_gd(H4, [-1.5 1.5], 'b');
  [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
  a=1;