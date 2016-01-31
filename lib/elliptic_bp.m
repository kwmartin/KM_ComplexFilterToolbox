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

function H = elliptic_bp(ps,wp,ni,e_)
% ni: number of loss poles at infinity
% ps: finite loss poles
% w1: lower passband edge
% w2: upper passband edge
% e_: passband ripple = sqrt(1 + e_^2)

np=length(ps); % number of finite loss poles (including zero)

% transform loss poles to s-plane and calculate denominator of H(s)
% which is the numerator of transfer function T(s)
pz = zpk([],[],1);
for i = 1:np % Find transformed finite jw axis poles
    wpp(i) = trnsfrm_wp(ps(i),wp); % wpp(i) is equal to pi^2
    pp(i) = zpk(tf([1 2*sqrt(wpp(i)) wpp(i)],1));
    pz = pz* pp(i);
end
for i = 1:ni % Find transformed poles at infinity
    pi(i) = zpk(tf([1 2 1],1));
    pz = pz*pi(i);
end

% fz is even part of pz
fz = (tf(pz) + tf(pz)')/2; % Convert to transfer function so cancellation is exact
fz = zpk(fz); % Convert back to zero, pole form
% fz = (pz + pz')/2;

% transform fz back to s plane
z = fz.z{1,1};
nz = length(z)/2;
for i = 1:nz
    z2(i) = z(2*i - 1)*z(2*i);
    wf(i) = trnsfrm_yf(z2(i),wp);
end
wf = wf.';

% find H by solving Feldtkeller's equation in the s domain
K = zpk(wf, ps, 1.0);
KK_ = K*K';
k = 1.0/abs(freqresp(K,wp(1)));
% The following commented out line worked in 2004, but not in 2016
% The replacement is a hack that seems to get around Matlab limitations handling
% complex coefficient transfer functions
%HH_ = 1 + e_^2*k^2*KK_;
HH_ = zpk(1 + tf(e_^2*k^2*KK_));

% choose LHP poles (which are zeros of HH_)
hh_z = HH_.z{1,1};
n = ni + np;
k = 1;
for i = 1:2*n
    if real(hh_z(i)) < 0
        we(k) = hh_z(i);
        k = k+1;
    end
end

% finally form transfer function and normalize gain
H = zpk(we,ps,1);
g = sqrt(1.0 + e_^2)/abs(freqresp(H,wp(1)));
H = g*H;
