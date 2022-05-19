function H2 = dsgnDigitalFltr2(p,px,ni,wp,ws,as,Ap,type,Ordr)
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

  ws1 = max(ws(ws < wp(1)));
  ws2 = min(ws(ws > wp(2)));
  if any((p < wp(1)) & (p > ws1)) | any((p > wp(2)) & (p < ws2))
    error('A moveable pole is in the transition region');
  elseif any((px < wp(1)) & (px > ws1)) | any((px > wp(2)) & (px < ws2))
    error('A fixed pole is in the transition region');
  end

  if nargin == 8
    Ordr = length(p) + length(px) + ni;
  elseif nargin ~= 9
    error('There should be 8 or 9 input arguments');
  end

  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as);

  ONE_STP = 0;
  if strcmp(type, 'monotonic') || strcmp(type, 'elliptic')
    [H1, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,type);
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
  elseif strcmp(type, 'bessel')
    % Ap = -Ap;
    H1 = bessel_filt(Ordr, wp, Ap);
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
  elseif strcmp(type, 'besselLsPls')
    H1 = besselLsPls(Ordr, Ap, 3);
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
  elseif strcmp(type, 'equiGD')
    deltT = 0.25;
    [H1 T0] = LinPhFltr(Ordr, 0.01, Ap); % design continous prototype
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
    H2 = adaptP2(H2,deltT);
    H2.k = H2.k/(abs(freqresp(H2,0)));
  elseif strcmp(type, 'equiGDLsPls')
    tic
    deltGD = 0.25;
    [H2, p, px, wp, ws, as] = dsgnEquiRplGD(p,px,wp,ws,as,Ap,Ordr,sclFctr,shftFctr,deltGD);
    toc

    % plot_drsps(H2,wp,'r',[-70 5]);
    f = -0.5:1e-4:0.5;
    w = 2*pi*f;
    s_ = j*w;
    figure;
    rdb = @(f,H)(db(rspsd(H,j*2*pi*f)));
    plot(f,rdb(f,H2));
    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H2, w(:));
    axis([-0.5 0.5 -100 2]);
    indx = find(gdH > 100);
    gdH(indx) = gdH(indx+1);
    indx = find(gdH < -100);
    gdH(indx) = gdH(indx+1);
    figure
    plot(f,gdH,'r','LineWidth',1);

    a = 1;
  end
  % plot_crsps(H1,wp,ws,'b',[-10 10 -100 1]);
  % plot_am_ph_gd(H4, [-1.5 1.5], 'b');
  % plot_dam_ph_gd(H2, [-0.5 0.5], 'b');
  % plot_drsps(H2,wp,'r',[-100 1]);
  a=1;