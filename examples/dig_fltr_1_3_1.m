% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = 2*pi*[-0.25 -0.15 0.25]; % initial guess at moveable finite loss poles
px = [0.0]; % fixed pole
ni=1; % number of loss poles at infinity
wpHz = [0.05 0.1];
wpRd = 2*pi*wpHz;
wp = 2*tan(wpRd./2.0); % predistort passband
ws = 2*pi*[-0.0 0.15]; % lower and upper stopband frequencies
as = [20 20];
Ap = 0.05; % the passband ripple in dB
type = 'monotonic'

H = design_dig_filt(p,px,ni,wp,ws,as,Ap,type);
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wpHz, ws, -160, 0);

a=1;