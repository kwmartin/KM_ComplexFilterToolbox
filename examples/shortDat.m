N = 500;
t = 0:(N-1);
xin = 1.0*sin(win.*t);
[Xfb, Xs] = simBckFrth(xin, k, G);