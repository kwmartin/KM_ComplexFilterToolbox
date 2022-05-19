z = @(w)(exp(j*w));
z1 = z(0);
z2 = z(0.1);
w1 = z(0);
w2 = z(pi);
T = @(x, z1, z2)((z(x) + 1/z(x) - z1 - 1/z1)/(z(x) + 1/z(x) - z2 - 1/z2));
A = @(w1, w2)(2/(cos(w1) - cos(w2)));
B = @(w1, w2)((-2*(cos(w1) + cos(w2)))/(cos(w1) - cos(w2)));
T2 = @(x, x1, x2)((cos(x) -cos(x1))/(cos(x) - cos(x2)));

w2x = @(w, w1, w2)(acos((-2*cos(w))/(cos(w2) - cos(w1)) + (cos(w2) + cos(w1))/(cos(w2)- cos(w1))));
x2w = @(x, w1, w2)(acos(-(cos(w2) - cos(w1))*cos(x)/2 + (cos(w2) + cos(w1))/2));
