% 5 movable loss-poles in lower stop and 2 movable loss poles in upper
% stop-band; cascade filter is then designed and simulated using Monte
% Carlo analysis

p = [-0.4 -0.25 -0.125 -0.1 -0.05 0.25 0.35]; % initial guess at finite loss poles
px = [];
ni=1; % number of loss poles at infinity
wp = [0.025 0.125];
ws = [0 0.2];
as = [20 20];

Ap = 0.025; % the passband ripple in dB

svSpecs = {p, px, wp, ws};

% Normalize specs, design prototype, unscale, apply biliear and unshift
tic
H4 = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,'elliptic');
toc
[ax1, ax2] = plot_drsps(H4, wp, ws, 'b', [-0.5 0.5 -160 1]);
%[a, b, c, d] = ssdata(H4);
%[sos,g] = ss2sos(a, b, c, d);

%[p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs
%sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
%[p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);

% A discrete-time filter with an equi-ripple pass-band
% This filter is designed directly without normalization
tic
H3 = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
%[H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
toc
plot_drsps(H3,wp,ws,'r', [-0.5 0.5 -160 1]);

%[p, px, wp, ws, H2] = invrsTrnsfrmH(H, p, px, wp, ws, sclFctr, shftFctr);

cscdFltr = dsgnCascadeFltr(p,px,ni,wp,ws,as,Ap,'elliptic');
cscdFltr.plotGn(wp, ws, -160, 2);

freq_shtf = 0.0;
tic
runMcCscd(cscdFltr, wp, 1e-4, freq_shtf, 100, [-160, 2]);
toc

%hndl(2) = figure('Position',[200 200 500 600]);
%plot_crsps(H2,wp,ws,'b',[-10 10 -120 0.5]);


a=1;