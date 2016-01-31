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

% The first two filters are analog (continuous-time) filters. The first of
% these has an equiripple passband, whereas the second one has a monotonic
% passband.

% The third and fourth filters are digital (discrete-time) filters again
% with equiripple and monotonic passbands.

% In all cases, the filters are complex with asymmetric (in frequency)
% responses.

p = [-2 -15 0 3 5]; % initial guess at finite loss poles; note pole at zero
ni=2; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = 1; % lower passband edge
wp(2) = 2; % upper passband edge
ws(1) = 0.05; % lower stopband edge
ws(2) = 2.5; % upper stopband edge
as = [20 20];
Ap = 0.1; % the passband ripple in dB
px = [];
% A positive-pass continuous-time filter with an equi-ripple pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
hndl(1) = figure('Position',[100 200 500 600]);
plot_crsps(H,wp,ws,'r');

% A positive-pass continuous-time filter with a monotonic pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
hndl(2) = figure('Position',[200 200 500 600]);
plot_crsps(H,wp,ws,'b');

pd = [ -.25 -.2   .25 .4]; % initial guess at finite loss poles
ni=2; % number of loss poles at infinity
wp(1) = 0.05; % lower passband edge
wp(2) = 0.15; % upper passband edge
ws(1) = 0.02; % lower stopband edge
ws(2) = 0.20; % upper stopband edge
as = [20 20];

Ap = 0.1; % the passband ripple in dB

% A discrete-time filter with an equi-ripple pass-band
H = design_dtm_filt(pd,px,ni,wp,ws,as,Ap,'elliptic');
hndl(3) = figure('Position',[300 200 500 600]);
plot_drsps(H,wp,ws,'r');

% A discrete time filter with a monotonic pass-band
H = design_dtm_filt(pd,px,ni,wp,ws,as,Ap,'monotonic');
hndl(4) = figure('Position',[400 200 500 600]);
plot_drsps(H,wp,ws,'b');

% The next example is a discrete-time filter without any loss-poles at
% fs/2. In this case, it may be desirable to treat the upper and lower-stop
% band as a single stop-band which is specified by setting ONE_STP = 1.
% This normally is done when ni=0. In this case, loss-poles can be moved
% from one stop-band to the other.

p = [ -.4 -.3 -0.05  -0.018  .35 .4 .45]; % initial guess at moveable finite loss poles
px = []; % fixed pole
ni=0; % number of loss poles at infinity
wp(1) = 0.025; % lower passband edge
wp(2) = 0.2; % upper passband edge
ws(1) = 0.00; % lower stopband edge
ws(2) = 0.3; % upper stopband edge

Ap = 0.1; % the passband ripple in dB
fig = figure('Position',[500 200 500 600]); % This places and sizes plot figure
H = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'monotonic'); %This is a discrete-time design with a fixed loss-pole at dc.
plot_drsps(H,wp,ws,'r',[-0.5 0.5 -120 1]); % Plot the response (with specified axis scaling

% The next example is a discrete-time filter that is a positive-pass filter
% over most of the positive frequencies and has stop-band attenuation
% specifications chosen to give significant attenuation at the
% corresponding negative image frequencies. The stopband attenuation is
% equi-ripple between -.4 and -0.05.

p = [ -.4 -.3 -.25 -0.05  -0.018  .495]; % initial guess at moveable finite loss poles
px = [0]; % fixed pole
ni=0; % number of loss poles at infinity
wp(1) = 0.05; % lower passband edge
wp(2) = 0.45; % upper passband edge
ws = [-0.49 -0.45 -0.05 0.01 0.49]; % upper and lower stopband frequencies
as = [0 60 60 20 20];

Ap = 0.1; % the passband ripple in dB
fig = figure('Position',[600 200 500 600]); % This places and sizes plot figure
H = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'monotonic'); %This is a discrete-time design with a fixed loss-pole at dc.
plot_drsps(H,wp,ws,'r',[-0.5 0.5 -120 1]); % Plot the response (with specified axis scaling)
