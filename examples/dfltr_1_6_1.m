% 6 moveable loss poles in lower stop-band and one fixed loss-pole at dc
% passband extends through most of positive frequencies, a good example of
% a positive-pass filter (Hilbert transform)

p = [ -.35 -.4 -.3 -.25 -0.05  -0.018 ]; % initial guess at moveable finite loss poles
px = [0]; % fixed pole
ni=1; % number of loss poles at infinity
wp(1) = 0.05; % lower passband edge
wp(2) = 0.45; % upper passband edge
ws = [-0.49 -0.45 -0.05 0.01 0.49]; % upper and lower stopband frequencies
as = [10 10 50 50 10];

Ap = 0.01; % the passband ripple in dB
H = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'elliptic'); %This is a discrete-time design with a fixed loss-pole at dc.
plot_drsps(H,wp,ws,'r',[-0.5 0.5 -120 1]); % Plot the response (with specified axis scaling)

