% _scld copy of dig_linPh_1_8_0.m - uses the _scld design chain
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

H = dsgnDigitalFltr_scld(p,px,ni,wp,ws,as,Ap,type,Ordr)
% figure
[ax1, ax2] = plot_drsps(H,wp,'b',[-120 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -120, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -120, 0, 'b');
a=1;