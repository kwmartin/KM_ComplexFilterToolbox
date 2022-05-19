% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = []; % initial guess at finite loss poles
px = [];
wp = [-0.05 0.05];
ws = [-0.499 -0.1 0.1 0.499];
as = [20 20 20 20];
ni = 15;
Ap=3.0103;
type = 'equiGD'
Ordr = ni;

H = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,type,Ordr)
figure
[ax1, ax2] = plot_drsps(H,wp,'b',[-40 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});

a=1;