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

H = dsgnDigitalFltr2(p,px,ni,wp,ws,as,Ap,type,Ordr);
deltGD=0.25;
% H = equiGdDigital(p,px,ni,wp,ws,as,Ap,type,deltGD,Ordr);
[ax1, axq2] = plot_drsps(H,wp,'b',[-200 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});

np = length(p);
p1 = H.z{1};
p1 = p1((p1 + 1) < 1e-7);
if length(p1) ~= Ordr
    error('There should be %d zeros',ni);
end
ni = Ordr - np;
p2 = exp(2*pi*p*j);
py = [-ones(ni,1); p2.'];
py = sortImag(py);
H2 = zpk(py, H.p{1}, H.k);
H3= place_polesdLP5(H2,wp);
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