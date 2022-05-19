%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next section works
N=64;
I = [0:N-1];
f0 = 1/N;
fp = I*f0;
wp = 2*pi*fp;
G = 1/(1*length(wp));

npts = 2/f0 + 1;
t = (0:(npts-1))';
% fin = f0*[3.5];
fin = f0*[4.0];
win = 2*pi*fin;
xin = sum(exp(1j*t(:)*win),2);

[Xfb, Xs, Xe, Y, Xp] = simBckFrthCmplx(xin, fp, G);
a=1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
