function Fltr = elliptic_dbp(ps,wp,ni,e_)
% [H, E, F, P] = elliptic_dbp(ps,wp,ni,e_) designs a digital elliptic band-pass transfer function
% the passband is equi=ripple magnitude.
% ni: number of loss poles at infinity
% ps: finite loss poles
% w1: lower passband edge
% w2: upper passband edge
% e_: passband ripple = sqrt(1 + e_^2)
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

w2z2 = @(w, wp) ((2.*tan(w./2) - wp(2))./(2*tan(w./2) - wp(1)));
z2w = @(z,wp)(2*atan((wp(2) - z^2*wp(1))/(2*(1 - z^2))));
np=length(ps); % number of finite loss poles (including zero)

% transform loss poles to y-plane
pz = zpk([],[],1);
wpp = abs(w2z2(ps, wp));
for i = 1:np % Find transformed finite jw axis poles
    pp(i) = zpk(tf([1 2*sqrt(wpp(i)) wpp(i)],1));
    pz = pz* pp(i);
end
for i = 1:ni % Find transformed poles at infinity
    pi_(i) = zpk(tf([1 2 1],1));
    pz = pz*pi_(i);
end

% fz is even part of pz
% fz = (tf(pz) + tf(pz)')/2; % Convert to transfer function so cancellation is exact
% fz = zpk(fz); % Convert back to zero, pole form
% fz = (pz + pz')/2;
p1 = polyClass(pz.z{1}, 1);
[fev, fodd] = getEvnOddPly(p1);
fz = zpk(fev.rts,[],1);

% transform fz back to s plane
z = fz.z{1,1};
nz = length(z)/2;
for i = 1:nz
    wf(i) = z2w(z(2*i - 1), wp);
end
wf = wf.';

wpsbnd = 2*atan(wp./2); % wp is pre-distorted, this goes back to specifications

% choose LHP poles (which are zeros of HH_)
pzz = sort(real(pz.z{1}));
pz = zpk(pzz,[],1);
Hx = findHx3(fz,pz,e_);
H = trnsfrmH2z(Hx,wp,e_);
[ax1, ax2] = plot_drsps(H,wpsbnd./(2*pi),'b',[-70 10]);
plotHx(Hx, e_, -300);

% finally form transfer function and normalize gain
F = wf.';
E = H.p{1};
P = ps;

Fltr = struct('H', H, 'E', E, 'F', F, 'P', P);
a = 1;

