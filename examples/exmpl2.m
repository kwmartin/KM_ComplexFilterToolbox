p = [ -.35 -.4 -.3 -.25 -0.05  -0.018 ]; % initial guess at moveable finite loss poles
px = [0]; % fixed pole
ni=1; % number of loss poles at infinity
wp(1) = 0.05; % lower passband edge
wp(2) = 0.45; % upper passband edge
ws = [-0.49 -0.45 -0.05 0.01 0.49]; % upper and lower stopband frequencies
as = [0 60 60 20 20];

Ap = 0.1; % the passband ripple in dB
H = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'monotonic'); %This is a discrete-time design with a fixed loss-pole at dc.
plot_drsps(H,wp,ws,'r',[-0.5 0.5 -120 1]); % Plot the response (with specified axis scaling)

