function [f, ndB, dB, ym, ya] = nfft(xin,c);
if nargin==2, colour=c; else, colour='m'; end
n=max(size(xin));
y=fft(xin);
ya=abs(y)/(n/2);
ym=ya./max(ya);
ndB=20*log10(ym+eps);
dB=20*log10(ya+eps);
f=0:1/n:1.0-1/n;
plot(f,ndB(1:n),colour);
axis([0, 1, min(ndB)-5, 0]);
y=y(:);
ya=ya(:);
dB=dB(:);
f=f(:);
