function H = design_dtm_filt(p,px,ni,wp,ws,as,ap,type)
% H = design_dtm_filt(p,px,ni,wp,ws,as,ap,type) design discrete-time transfer function
% This is a routine for designing discrete-time complex transfer functions
% This has been replaced at 11/2018 by approach that does desing between +-1
% p: initial guess at finite MOVEABLE loss poles, px is fixed poles
% ni: number of loss poles at infinity, wp is pass-band, ws is stop-band
% as is a vector specifying db loss at stop-band freqs, ap is pass-band ripple in dB
% type is 'monotonic' for a maximally flat pass-band and 'elliptic' for
% an equi-ripple pass-band
% ONE_STP = 1 to treat the entire stop-band both above and below the
% pass-band as a single pass-band. This can be preferable when there are
% no poles at infinity (0.5 for digital filters). This choice allows poles
% to move between pass-bands. When ni is not equal to zero, then ONE_STP =
% 0 may be preferable. Try experimenting.
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

warning off all % The control toolbox is giving too many warnings with complex variables
Ap = ap; % desired passband ripple

if nargin ~= 8
    error('There should be 8 inputs: pd (initial pole vector), px (fixed poles), ni, wd (freq. specs), a (atten.), and type')
end

wsb1 = max(ws(ws < wp(1)));
wsb2 = min(ws(ws > wp(2)));

% Check for loss-poles not in stop-band
poles1 = p(p <= wsb2);
poles2 = poles1(poles1 >= wsb1);
if any(poles2)
    error('Some initial pole estimates are between the stopband frequencies')
end

poles1 = px(px <= wsb2);
poles2 = poles1(poles1 >= wsb1);
if any(poles2)
    error('Some fixed poles are between the stopband frequencies')
end

if (sort(ws ~= ws))
    error('The stopband specifications are not monotonically increasing')
end

if (length(ws) ~= length(as))
    error('The number of stopband specification frequencies and number of amplitued specifications do not match')
end

e_ = sqrt(10^(Ap/10) - 1.0); % passband ripple = sqrt(1 + e_^2)

% Predistort all specification frequencies
p = 2*tan(pi*p);
px = 2*tan(pi*px);
wp = 2*tan(pi*wp);

indice = (ws ~= 0.5);
ws = ws(indice);
as = as(indice);
ws = [-0.499 ws 0.499];
as = [as(1) as as(length(as))];
ws = 2*tan(pi*ws);

% Make characteristic function in s'
if length(p) >=1 % We have moveable poles
	% This is what should be used Kz = place_poles2(p,px,ni,[w1,w2,w3,w4],e_,type); % Place poles
	Kz = place_poles(p,px,ni,wp,ws,as,e_,type); % Place poles
else % Only fixed poles
    Kz = make_init2Kz(p,px,ni,wp,type); % No placement required
end

[margin, smin] = disp_margin(Kz,ws,as,wp,e_,'discrete');

% Transform loss-poles back to s domain
[p,np] = get_poles(Kz,[1]);  % return poles except poles at infinity (s' = 1)

if (np >=1)
    ps = z2s(p,wp);
	ps = j*sort(imag(ps));
else
    ps = [];
    np =0;
end

% Find reflection zeros, and H(s)
switch type
    case 'elliptic'
		Hc = elliptic_bp(ps,wp,ni,e_);
    case 'monotonic'
        Fltr = monotonic_bp(ps,wp,ni,e_);
        Hc = Fltr.H;
        E = Fltr.E;
        F = Fltr.F;
        P = Fltr.P;
    otherwise
        error('The fifth argument must be either elliptic or monotonic');
end

A = 20*log_rsps(Hc,j*2*tan(pi*[wsb1 wsb2]));
sprintf('Lower Stopband Edge Attenuation: %4.2fdB',A(1))
sprintf('Upper Stopband Edge Attenuation: %4.2fdB',A(2))
H2 = inv(Hc);

% The bilinear function in the Control toolbox does not work with complex
% systems; however, the bilinear function in the signal processing toolbox
% does
[z p k] = zpkdata(H2, 'v');
% Transform to discrete-time system using bilinear transform
[zd pd kd] = bilinear(z,p,k,1);
H = zpk(zd,pd,kd,1); % Make zero, pole system
warning on all
