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

function H = design_ctm_flt(p,px,ni,wp,ws,as,ap,type)
% This is a program for designing a continous-time complex IIR filter.

warning off all % The control toolbox is giving too many warnings with complex variables
wsb1 = max(ws(ws < wp(1)));
wsb2 = min(ws(ws > wp(2)));

% p: Initial guess at finite loss poles
% px: fixed poles
% ni: number of poles at infinity

% a is the desired pass-band ripple in dB.

% type is 'monotonic' for a maximally flat pass-band and 'elliptic' for
% and equi-ripple pass-band

% ONE_STP = 1 to treat the entire stop-band both above and below the
% pass-band as a single pass-band. For continuous-time filters, normally ONE_STP=0.
% ONE_STP = 1can be preferrable when there are
% no poles at infinity (0.5 in the discrete domain) for digital filters. This choice allows poles
% to move between pass-bands. When ni is not equal to zero, then ONE_STP =
% 0 may be preferrable. Try experimenting.

if nargin ~= 8
    error('There should be 8 inputs: p (initial moveable pole vector), px (fixed poles), ni, wd (freq. specs), a (atten.), and type')
end
poles1 = p(p <= wsb2);
poles2 = poles1(poles1 >= wsb1);
if any(poles2)
    error('Some initial pole estimates are not in the specified stopband frequencies')
end

poles1 = px(px <= wsb2);
poles2 = poles1(poles1 >= wsb1);
if any(poles2)
    error('Some fixed poles are between the stopband frequencies')
end

Ap = ap; % desired passband ripple

e_ = sqrt(10^(Ap/10) - 1.0); % passband ripple = sqrt(1 + e_^2)

ws = [-100 ws 100];
as = [as(1) as as(length(as))];

if length(p) >=1
	Kz = place_poles(p,px,ni,wp,ws,as,e_,type);
else
    Kz = make_init2Kz(p,ni,wp,type);
end

[margin, smin] = disp_margin(Kz,ws,as,wp,e_,'continuous');

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
		H = elliptic_bp(ps,wp,ni,e_);
    case 'monotonic'
		H = monotonic_bp(ps,wp,ni,e_);
    otherwise
        error('The fifth argument must be either elliptic or monotonic');
end

A = 20*log_rsps(H,j*[wsb1 wsb2]);
sprintf('Lower Stopband Edge Attenuation: %4.2fdB',A(1))
sprintf('Upper Stopband Edge Attenuation: %4.2fdB',A(2))

H = inv(H);
warning on all
