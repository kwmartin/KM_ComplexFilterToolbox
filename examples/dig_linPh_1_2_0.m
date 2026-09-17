% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

% p = [-0.2 -0.1 0.1 0.2]; % initial guess at finite loss poles
% px = [];
% wp = [-0.06 0.06];
% ws = [-0.49999 -0.10 0.10 0.49999];

p = [-0.1 -0.06 0.06 0.1]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.025; % lower passband edge
wp(2) = 0.025; % upper passband edge
ws = [-0.49 -0.049 0.049 0.49];

as = [20 20 20 20];
ni = 1;
% Ap=3.0103;
Ap = 2.0;
type = 'equiGDLsPls'
% Ordr = 5;



% as = [20 20 20 20];
% ni = 1;
% Ap=3.0103;
% Ap = 1;
% type = 'equiGDLsPls'
Ordr = 5;

H = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type,Ordr)
[ax1, ax2] = plot_drsps(H,wp,'b',[-40 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
a=1;