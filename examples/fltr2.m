% A simple ladder filter from example 9 of
% Snelgrove, Sedra, Lang Brackett, "Complex Analog Filters"

wp = [-1, 1];
ws = [-2, 2];
prts = [-0.149524j];
erts = [-0.1696624+1.05598j, -0.107248+0.612356j];
E = zpk(erts, [], 1);
P = zpk(prts, [], 1);
H= P/E;
Ppl = polyClass(prts, 1);
[Pev, Pod] = getEvnOddPly(Ppl);
wp = [0.6 1.1];
ni = 1;
Ap = 1.0;
e_ = sqrt(10^(Ap/10) - 1.0);
[H, E, F, P] = elliptic_bp(prts,wp,ni,e_);
H = 1/H;
plot_crsps(H,wp,ws,'b',[-2 2 -80 2.0]);
Zin = mkZin(E, F);

lddr = ladderClass();
[X2, elem1, elem2] = rmvUsingS2(Zin, prts(1), lddr);
[X3, elem3] = rmvSCmplx(X2, lddr);
lddr.R2 = X3.K;
dispLddr(lddr);

lddr2 = ladderClass();
elems(1) = elem1;
elems(2) = elem2;
elems(3) = elem3;
for i = 1:length(elems)
    lddr2.addElem(elems(i));
end
lddr2.R1 = 1;
lddr2.R2 = 5.42998;
dispLddr(lddr2);
%lddr.R2 = 0.3913;
lim = [-2, 2, -60, 10,];
[fdb, fref_db] = plot_lddr(H, lddr, wp, ws, 'b', lim);

s = tf('s');
%Yin1 = 0.3913 + s*2.8523 -1/2.3855j;
%z2 = 7.0254j;
%z3 = 1/(s*0.1528 - 1/43.772j);
%z4 = z2 + z3;
%y4 = 1/z4;
%Yin4 = 1/(z4 + 1/Yin1);
%Yin5 = 1/0.1423j + Yin4;
%tf1 = 1/(1 + Yin5);
%tf2 = y4/(y4 + Yin1);
Yin1 = 0.184163 -1.2090j + s*0.66509;
y2 = 0.1101j + s*0.73634;
z2 = 1/y2;
Yin2 = 1/(z2 + 1/Yin1);
Yin3 = -6.0770j + s*6.8734 + Yin2;
tf1 = 1/(1 + Yin3);
tf2 = y2/(y2 + Yin1);
tf3 = tf1*tf2;
H2 = zpk(tf3);
plot_crsps(H2,wp,ws,'g',[-2 2 -50 5]);
a=1;
