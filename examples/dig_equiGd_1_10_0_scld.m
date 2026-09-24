% _scld copy of dig_equiGd_1_10_0.m - uses the _scld design chain (adaptP2_scld)
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
% Ap=1.0;
np = length(p);
ni = 1;

deltGD=0.25;
useWs = 1;
H = equiGdDigital_scld(p,px,ni,wp,ws,as,Ap,deltGD,useWs);
figure
[ax1, axq2] = plot_drsps(H,wp,'b',[-150 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -150, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -150, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});


a=1;