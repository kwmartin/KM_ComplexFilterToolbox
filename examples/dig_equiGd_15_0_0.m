% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = [-0.4 -0.2 0.2 0.4]; % initial guess at finite loss poles
px = [];
wp = [-0.05 0.05];
ws = [-0.499 -0.1 0.1 0.499];
as = [20 20 20 20];
% ni = 15;
Ap=3.0103;
np = length(p);
ni = 7;
type = 'equiGD'
% type = 'equiGDLsPls'
Ordr = ni + np;

H = dsgnDigitalFltr2(p,px,ni,wp,ws,as,Ap,type,Ordr);
deltGD=0.25;
figure
[ax1, axq2] = plot_drsps(H,wp,'b',[-200 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});

% Stopband-equalized version: this used to hand-rebuild H's zeros from p
% and call place_polesdLP5 directly (the same steps equiGdDigital.m does
% internally) -- replaced with the actual function call, which is the
% tested/maintained version of this same logic.
useWs = 0; % matches the original 2-arg place_polesdLP5(H2,wp) call
H3 = equiGdDigital(p,px,ni,wp,ws,as,Ap,deltGD,useWs);
a=1;