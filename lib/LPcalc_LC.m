function [L, C, H] = LPcalc_LC(Rs, Rl, w0, Q)
% [C, L] = LPcalc_LC(Rs, Rl, w0, Q) finds L & C of second-order LP

gs = 1/Rs;
gl = 1/Rl;
b = (gl + gs)/(w0*Q);
c = (gl + gs)*gs/(w0^2);
C = b/2 + sqrt((b/2)^2 - c);
L = Rl*(gl + gs)/(C * w0^2);
D = [L*C/(1 + gs/gl), (L*gl + C/gs)*gs/(gs + gl), 1];
N =[gs/(gs + gl)];
H = tf(N, D);
a = 1;

