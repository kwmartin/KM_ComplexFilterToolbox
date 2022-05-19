% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = [-0.15 0.3]; % initial guess at finite loss poles
px = [];
wp = [-0.0 0.1];
ws = [-0.49999 -0.1 0.2 0.49999];
as = [20 20 20 20];
ni = 1;
Ap=3.0103;
% Ap = 1;
type = 'equiGDLsPls'
Ordr = 3;

H = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type,Ordr)
figure
[ax1, ax2] = plot_drsps(H,wpHz,'b',[-40 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -80, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wpHz, ws, -80, 0, 'b');
a=1;