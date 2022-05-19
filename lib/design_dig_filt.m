function [H, E, F, P, e_] = design_dig_filt(p,px,ni,wp,ws,as,ap,type)
%   [H, E, F, P, e_] = design_dig_filt(p,px,ni,wp,ws,as,ap,type)
%   Design a discrete-time complex IIR transfer function
%   p: Initial guess at finite loss poles; actual values not important as
%   long as they are in the stop-band; this spec is mostly used to decide the order.
%   px: fixed poles; often used to have a loss-pole at dc or the carrier frequency.
%   ni: number of poles at infinity of the continuous-time prototype. They result in
%   loss-poles at half the sample frequency
%   wp: the pass-band frequencies; there should be two in radians
%   ws: the stop-band frequencies; at least two, but there can be more than two;
%   the number of frequencies should match the size of as; all loss-pole frequencies
%   (p, and px) should be in the stop-bands
%   as: the specifications for desired attenuation at each stop-band frequency;
%   he actual attenuation is determined by the order and how wide the transition
%   region is, but generally the DIFFERENCES in attenaution at the ws frequencies
%   is determined by the as specifications. as values should all be positive
%   ap: the desired pass-band ripple in dB; normally this spec. is met exactly.
%   type: 'monotonic' for a maximally flat pass-band and 'elliptic' for an
%   equi-ripple pass-band
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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

% The control toolbox is giving too many warnings with complex sys objects
% this tool-box looks after the fact Matlab does not support complex systems
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

if nargin ~= 8
    error('There should be 8 inputs: p (initial moveable pole vector), px (fixed poles), ni (number of poles at infinity), wp (pass-band frequencies), ws (stop-band frequencies), as (stop-band atten.), as (pass-band atten.) and type')
end

% find the edges of the transition regions
wsb1 = max(ws(ws < wp(1)));
wsb2 = min(ws(ws > wp(2)));

% check in any initial frequencies for moveable poles
% are in transition region
poles1 = p(p <= wsb2);
poles2 = poles1(poles1 >= wsb1);
if any(poles2)
    error('Some initial pole estimates are not in the specified stopband frequencies')
end

% check in any initial frequencies for fixed poles
% are in transition region
poles1 = px(px <= wsb2);
poles2 = poles1(poles1 >= wsb1);
if any(poles2)
    error('Some fixed poles are between the stopband frequencies')
end

% Note: the magnitude passband ripple = sqrt(1 + e_^2)
e_ = sqrt(10^(ap/10) - 1.0);

% extend the stop-band to frequencies far from pass-band
ws = [-0.5*2*pi ws 0.5*2*pi];
as = [as(1) as as(length(as))];

if length(p) >=1
  % place_poles is one of the most important functions used in approximation
  % Kz is K polynomial in y domain
	Kz = place_polesd(p,px,ni,wp,ws,as,e_,type);
	% KySq = place_polesd2(p,px,ni,wp,ws,as,e_,type);
  % place_polesd2 is experimental and unfinished and not needed
else
    Kz = make_init2Kzd(p,px,ni,wp,type);
end

% check the margin to ensure they are equal in each stop-band
% to ensure the pole placement routines converged
[margin, smin] = disp_margind(Kz,ws,as,wp,e_,'continuous');

% return the loss poles from Kz
[p,np] = get_poles(Kz,[1]); % return poles except poles at infinity (s' = 1)
% [p2,np2] = get_poles2(KySq,[1]); % return poles except poles at infinity (s' = 1)

if (np >=1)
  ps = x2pd(p,wp);
  ps = sortRootsD(ps);
  ws = real(-j*log(ps));
else
  ps = [];
  np =0;
end

switch type
  case 'elliptic'
    Fltr = elliptic_dbp(ws,wp,ni,e_);
  case 'monotonic'
    Fltr = monotonic_dbp(ws,wp,ni,e_);
  otherwise
    error('The type argument must be either elliptic or monotonic');
end

H = Fltr.H;
E = Fltr.E;
F = Fltr.F;
P = Fltr.P;

% return the gain transfer fucntion, not the loss function
warning on all
