% Quarter-band digital filter with 5 movable loss-poles at negative
% frequencies, 1 fixed loss-pole at dc, 2 movable loss-poles above
% pass-band and 1 loss-pole at infinity; just approximation, no realization

p = [ -.4 -.3 -.25 -0.05  .35 .48]; % initial guess at moveable finite loss poles
px = [0]; % fixed pole
ni=1; % number of loss poles at infinity
wp(1) = 0.05; % lower passband edge
wp(2) = 0.25; % upper passband edge
ws = [-0.49 -.29 -0.25 -0.05 0.01 0.29 0.49]; % upper and lower stopband frequencies
as = [5 5 5 15 25 5 5];

Ap = 0.025; % the passband ripple in dB
ONE_STP = 1; % treat both sto-bands as a single stop-band
H = design_dtm_filt(p,px,ni,wp,ws,as,Ap,'elliptic'); %This is a discrete-time design with a fixed loss-pole at dc.
plot_drsps(H,wp,ws,'r', [-0.5 0.5 -120 2]); % Plot the response (with specified axis scaling)

