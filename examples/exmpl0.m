% no finite loss-poles, three loss poles at infinity, 
% passband is -0.62 rad to 0.62 rad.
% just an example to show real low-pass filters can be designed

p = []; % initial guess at finite loss poles
ni=3; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.618034; % lower passband edge
wp(2) = 0.618034; % upper passband edge
ws = [-5 -1.5 1.5 5];
as = [30 30 30 30];
Ap = 3.0103; % the passband ripple in dB
px = [];
ONE_STP = 0;
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
plot_crsps(H,wp,ws,'b',[-10 10 -120 0.5]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXs(H, F, length(P));
rts = imag(P);
wps = sort(rts(rts > 0));

a = 1;
