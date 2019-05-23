% 2 movable poles, 1 pole at infinity, 1 fixed pole,
% wp = -0.0125 to 0.0125, 0.1dB elliptic passband
% includes Monte-Carlo run of 100 samples

p = [-0.25  0.25]; % initial values of moveable transmission zeros
px = [-0.025]; % fixed transmission zero
% it will be at dc after frequency shift of specs
ni=1; % number of loss poles at infinity
wp(1) = -0.0125; % lower passband edge
wp(2) = 0.0125; % upper passband edge
ws = [-0.024 0.024]; % lower and upper stopband frequencies
as = [20 20]; % attenuation goals

Ap = 0.1; % the passband ripple in dB
ONE_STP = 0; % treat both stop-bands as a single stop-band

% frequency shift specs so pass band is at positive frequencies
% from 0.0125 to 0.0375
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.025); 

cscdFltr = dsgnCascadeFltr(p_,px_,ni,wp_,ws_,as,Ap,'elliptic');
% plot cascade filter using object function
cscdFltr.plotGn(wp_, ws_, -80, 2);

tic
% simulate cascade filter 100 times with SS matrix elements
% varying by 0.01%
runMcCscd(cscdFltr, wp_, 1e-4, 0, 100, [-80, 2]);
toc

drawnow;
cscdHndl = gcf;
print('Figures/csc_fltr_1_2_1_MC','-dpng');

a=1;