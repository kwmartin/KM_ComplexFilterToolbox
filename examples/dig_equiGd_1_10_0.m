% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = [-0.3 -0.25 -0.2 -0.15 -0.1 0.1 0.15 0.2 0.25 0.3]; % initial guess at finite loss poles
px = [];
N = 64;
wp = [-0.5/N 0.5/N];
ws = [-0.499 2.0*wp 0.499];
as = [20 20 20 20];
% ni = 15;
Ap=3.0103;
np = length(p);
ni = 1;

deltGD=0.25;
H = equiGdDigital(p,px,ni,wp,ws,as,Ap,deltGD);
figure
[ax1, axq2] = plot_drsps(H,wp,'b',[-200 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});


a=1;