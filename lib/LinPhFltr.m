function [H T0] = LinPhFltr(n, deltT, ap)
%   [H T0] = LinPhFltr(n, deltT) returns an all-pole filter or order n having equi-ripple
%   group delay. T0 is the average passband delay
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
  warning('off', 'Control:ltiobject:ZPKComplex');

  options = optimoptions('fsolve','Display','none');
  options.FunctionTolerance = 1e-16;
  options.OptimalityTolerance = 1e-8;
  options.StepTolerance = 1e-8;
  options.MaxFunctionEvaluations = 5000;
  options.MaxIterations = 1000;

  h1 = bessel_filt(n, [-1 1], 3.0103);
  [z1 p1 k] = zpkdata(h1,'vector');
  Fctr = (n + 1.2)/3.2;
  p1 = p1./Fctr;
  s2z = @(s)-sqrt(1 + 1./(s.^2));
  z2s = @(z)-1./sqrt(z.^2 - 1);
  Z1 = s2z(p1).';
  fndRts = @(x)besselRts(x, deltT);
  rts = fsolve(fndRts,[Z1 n],options);
  p2 = z2s(rts(1:end-1)).';
  p2 = cplxpair(p2, 1e-7);
  T0 = rts(end);
  h2 = zpk(z1, p2, k);
  [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, 0);
  h2.k = h2.k/exp(lgH);

  w = 1;
  ep = -ap*log(10)/20; % desired loss in nepers
  for i = 1:10
    [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, w);
    w = w - (lgH - ep)./dLdW;
  end
  H = scaleFltr(h2, 1.0/w);

 for j = 1:5
    fndRts = @(x)besselRts(x, deltT/w);
    rts = fsolve(fndRts,rts,options);
    p2 = z2s(rts(1:end-1)).';
    p2 = cplxpair(p2, 1e-7);
    T0 = rts(end);
    h2 = zpk(z1, p2, k);
    [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, 0);
    h2.k = h2.k/exp(lgH);
    w = 1;
    ep = -ap*log(10)/20; % desired loss in nepers
    for i = 1:10
      [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, w);
      w = w - (lgH - ep)./dLdW;
    end
  end
  H = scaleFltr(h2, 1.0/w);

  % plot_am_ph_gd(H, [-1.5 1.5], 'b');
  % plot_crsps(H,wp,ws,'b',[-10 10 -120 1]);
  [deltT deriv] = fnd_gd_ripple(H,[0 1]);
  
  a = 1;
