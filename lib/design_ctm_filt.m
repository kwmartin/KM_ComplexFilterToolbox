function [H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,ap,type)
%   [H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,ap,type) cont. time filt.
%   Design a continuous-time IIR transfer function to meet specifications
%   p: Initial guess at finite loss poles; actual values not important as
%   long as they are in the stop; this spec is mostly used to decide the
%   order.
%
%   This routine is the most critical one in the toolbox
%
%   px: fixed poles; often used to have a loss-pole at dc or the carrier
%   frequency.
%
%   ni: number of poles at infinity
%
%   wp is the pass-band frequencies; there should be two
%
%   ws is the stop-band frequencies; at least two, but there can be more
%   the number of frequencies should match the size of as; all loss-pole
%   frequencies (p, and px) should be in the stop-bands
%
%   as is the specifications for desired attenuation at each stop-band
%   frequency; the actual attenuation is determined by the order and how
%   wide the transition region is, but generally the DIFFERENCES in attenaution
%   at the ws frequencies is determined by the as specifications. as values
%   should all be positive
%
%   ap is the desired pass-band ripple in dB; normally this spec. is met
%   exactly.
%
%   type is 'monotonic' for a maximally flat pass-band and 'elliptic' for
%   and equi-ripple pass-band
%
%   ONE_STP = 1 to treat the entire stop-band both above and below the
%   pass-band as a single pass-band. For continuous-time filters, normally ONE_STP=0.
%   ONE_STP = 1 can be preferrable when there are
%   no poles at infinity (0.5 in the discrete domain) for digital filters. This
%   choice allows poles to move between pass-bands. When ni is not equal to zero,
%   then ONE_STP = may be preferrable. Try experimenting.
%
%   Ken Martin: 11/24/03
%   Revised: 10/20/18
%   $Revision: 0.01 $  $Date: 11/24/03
%
%   For detailed explanation see:
%   K. Martin, “Approximation of complex iir bandpass filters without arith-
%   metic symmetry,” IEEE Trans. Circuits and Systems I, vol. 52, pp. 794–
%   803, April 2005.
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
ws = [-100 ws 100];
as = [as(1) as as(length(as))];

if length(p) >=1
  % place_poles is one of the most important functions used in approximation
  % Kz is K polynomial in z domain (note: this z is not e^(jwT))
	Kz = place_poles(p,px,ni,wp,ws,as,e_,type);
else
    Kz = make_init2Kz(p,px,ni,wp,type);
end

% check the margin to ensure they are equal in each stop-band
% to ensure the pole placement routines converged
[margin, smin] = disp_margin(Kz,ws,as,wp,e_,'continuous');

% return the loss poles from Kz
[p,np] = get_poles(Kz,[1]); % return poles except poles at infinity (s' = 1)

if (np >=1)
  ps = z2s(p,wp);
  ps = j*sort(imag(ps));
else
  ps = [];
  np =0;
end

switch type
  case 'elliptic'
    [H, E, F, P] = elliptic_bp(ps,wp,ni,e_);
  case 'monotonic'
    Fltr = monotonic_bp(ps,wp,ni,e_);
    H = Fltr.H;
    E = Fltr.E;
    F = Fltr.F;
    P = Fltr.P;
  otherwise
    error('The type argument must be either elliptic or monotonic');
end

% get the attenuation in dB
A = 20*log_rsps(H,j*[wsb1 wsb2]);
if ~isempty(wsb1)
    sprintf('Lower Stopband Edge Attenuation: %4.2fdB',A(1))
end
if ~isempty(wsb2)
    sprintf('Upper Stopband Edge Attenuation: %4.2fdB',A(2))
end

% return the gain transfer fucntion, not the loss function
H = inv(H);
warning on all
