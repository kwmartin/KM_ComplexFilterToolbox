% The next example is a discrete-time filter that is a positive-pass filter
% over most of the positive frequencies and has stop-band attenuation
% specifications chosen to give significant attenuation at the
% corresponding negative image frequencies.

p = [-.45 -.4 -.3 -.25 -0.05  -0.018 ]; % initial guess at moveable finite loss poles
px = [0 0]; % fixed pole
ni=2; % number of loss poles at infinity
wp(1) = 0.05; % lower passband edge
wp(2) = 0.45; % upper passband edge
ws = [-0.49 -0.45 -0.05 0.01 0.49]; % upper and lower stopband frequencies
as = [0 10 20 30 20];

Ap = 0.0025; % the passband ripple in dB
ONE_STP = 1; % treat both stop-bands as a single stop-band
H = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'elliptic'); %This is a discrete-time design with a fixed loss-pole at dc.
plot_drsps(H,wp,ws,'r',[-0.5 0.5 -120 1]); % Plot the response (with specified axis scaling)
