% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = [-0.2 0.2]; % initial guess at finite loss poles
wp = [-0.05 0.05];
ws = [-0.499 -0.1 0.1 0.499];
as = [20 20 20 20];
ni = 0;
Ap=3.0103;
type = 'equiGDLsPls'

Ordr = 3;
H = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type,Ordr)
[ax1, ax2] = plot_drsps(H,wpHz,'b',[-20 40]);
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wpHz, ws, -40, 0, 'b');
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
a=1;