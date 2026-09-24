% _scld copy of dig_equiGd_3_4_0.m - uses the _scld design chain (adaptP2_scld)
% One of the early examples used in developing normalized design

p = [-0.4 -0.3 -0.25 -0.2 -0.15 0.15 0.2 0.25 0.3 0.4]; % initial guess at finite loss poles
px = [];
N = 64;
wp = [-0.5/N 0.5/N];
ws = [-0.499 -0.1 0.1 0.499];
as = [20 20 20 20];
% ni = 15;
% Ap=3.0103;
Ap=1.0;
np = length(p);
ni = 1;
type = 'equiGD'
% type = 'equiGDLsPls'
Ordr = ni + np;

H = dsgnDigitalFltr2_scld(p,px,ni,wp,ws,as,Ap,type,Ordr);
deltGD=0.25;
[ax1, axq2] = plot_drsps(H,wp,'b',[-200 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});

% Stopband-equalized version: this used to hand-rebuild H's zeros from p
% and call place_polesdLP5 directly (the same steps equiGdDigital_scld.m does
% internally) -- replaced with the actual function call, which is the
% tested/maintained version of this same logic.
useWs = 0; % matches the original 2-arg place_polesdLP5(H2,wp) call
H3 = equiGdDigital_scld(p,px,ni,wp,ws,as,Ap,deltGD,useWs);
plotDig(H3);
plotGDd(H3)

figure
[ax1, axq2] = plot_drsps(H3,wp,'b',[-300 1]);
plot_dam_ph_gd(H3, [-0.5 0.5], -300, 'b');
cscdFltr = mkCscdFltrD2(H3, wp);
plotSimCscd(cscdFltr, wp, ws, -300, 0, 'b');
gdHs = hgdMake(H3);
gd = hzPlot(gdHs{2});

a=1;