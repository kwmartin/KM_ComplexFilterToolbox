% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = [-0.4 -0.35 -0.3 -0.2 0.28 0.3 0.4 0.45]; % initial guess at finite loss poles
px = [];
wp = [0.05 0.06];
ws = [-0.49999 -0.1 0.22 0.49999];
as = [20 20 20 20];
ni = 1;
% Ap=3.0103;
Ap = 2.0;
type = 'equiGDLsPls'
Ordr = 9;

H = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type,Ordr)
% figure
% [ax1, ax2] = plot_drsps(H,wpHz,'b',[-40 1]);
% plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -70, 0, 'b');
a=1;