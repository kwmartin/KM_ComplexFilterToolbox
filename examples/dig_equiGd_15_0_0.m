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
Ordr = ni;

H = dsgnDigitalFltr2(p,px,ni,wp,ws,as,Ap,type,Ordr);
deltGD=0.25;
% H = equiGdDigital(p,px,ni,wp,ws,as,Ap,type,deltGD,Ordr);
figure
[ax1, axq2] = plot_drsps(H,wp,'b',[-200 1]);
plot_dam_ph_gd(H, [-0.5 0.5], -40, 'b');
cscdFltr = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr, wp, ws, -40, 0, 'b');
gdHs = hgdMake(H);
gd = hzPlot(gdHs{2});

np = length(p);
p1 = H.z{1};
p1 = p1((p1 + 1) < 1e-7);
if length(p1) ~= ni
    error('There should be %d zeros',ni);
end
ni = ni - np;
p2 = exp(2*pi*p*j);
py = [-ones(ni,1); p2.'];
py = sortImag(py);
H2 = zpk(py, H.p{1}, H.k);
H3= place_polesdLP4(H2,wp);
a=1;