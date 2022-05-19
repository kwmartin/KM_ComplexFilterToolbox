% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = 2*pi*[-0.25 0.25]; % initial guess at moveable finite loss poles
px = []; % fixed pole
ni=1; % number of loss poles at infinity
wp(1) = 2*pi*0.05; % lower passband edge
wp(2) = 2*pi*0.1; % upper passband edge
wp = 2*tan(wp./2.0); % predistort passband
ws = 2*pi*[-0.0 0.15]; % lower and upper stopband frequencies
as = [20 20];
Ap = 1.0; % the passband ripple in dB
type = 'monotonic'

H = design_dig_filt(p,px,ni,wp,ws,as,Ap,type);

a=1;