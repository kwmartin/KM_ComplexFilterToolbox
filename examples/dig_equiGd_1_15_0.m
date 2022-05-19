% One of the early examples used in developing normalized design
% Includes the first SFG ladder simulation

p = [-0.4 -0.3 -0.25 -0.2 -0.15 0.15 0.2 0.25 0.3 0.4]; % initial guess at finite loss poles
px = [];
N = 64;
wp = [-0.5/N 0.5/N];
ws = [-0.499 -0.1 0.1 0.499];
as = [20 20 20 20];
% ni = 15;
% Ap=3.0103;
Ap = 1.0;
np = length(p);
ni = 15;
% type = 'equiGDLsPls'
Ordr = ni;

deltGD=0.05;
H = equiGdDigital(p,px,ni,wp,ws,as,Ap,deltGD,Ordr);
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
% gdHs = hgdMake(H);
% gd = hzPlot(gdHs{2});

plotDig(H, -450);
plotGDd(H)

a=1;