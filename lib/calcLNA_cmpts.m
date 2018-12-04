% Not used for complex filters; was used in a different project, not sure why it's here
% Will delete later
%
% [l1, c1, H] = LPcalc_LC(Rs, Rl, w0lp, Q); makes a second order low-pass
% with unequal terminations
% [L1, C1] = LP2BP(0, c1*w0lp, B1, w0bp) transforms cl to the bandpass realization


w0lp=2*pi*34e9;
Q=1/sqrt(2);
Rs=50;
Rl=50;
[l1, c1, H] = LPcalc_LC(Rs, Rl, w0lp, Q);
B1=2*pi*34e9;
w0bp=2*pi*40e9;
[L1, C1] = LP2BP(0, c1*w0lp, B1, w0bp)
[L2, C2] = LP2BP(l1*w0lp, 0, B1, w0bp)

[l2, c2, H] = LPcalc_LC(100, Rl, w0lp, Q);
B2=2*pi*22e9;
[L3, C3] = LP2BP(0, c2*w0lp, B2, w0bp)
[L4, C4] = LP2BP(l2*w0lp, 0, B2, w0bp)
B3=2*pi*16e9;
[l3, c3, H] = LPcalc_LC(1e5, 300, w0lp, Q);
