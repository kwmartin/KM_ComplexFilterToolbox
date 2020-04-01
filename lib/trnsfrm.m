z = @(w)(exp(j*w));
z1 = z(0);
T = @(x, z1, z2)((z(x) + 1/z(x) - z1 - 1/z1)/(z(x) + 1/z(x) - z2 - 1/z2));
A = @(w1, w2)(2/(cos(w1) - cos(w2)));
B = @(w1, w2)((-2*(cos(w1) + cos(w2)))/(cos(w1) - cos(w2)));
T2 = @(x, x1, x2)((cos(x) -cos(x1))/(cos(x) - cos(x2)));

w2x = @(w, w1, w2)(acos((-2*cos(w))/(cos(w2) - cos(w1)) + (cos(w2) + cos(w1))/(cos(w2)- cos(w1))));
x2w = @(x, w1, w2)(acos(-(cos(w2) - cos(w1))*cos(x)/2 + (cos(w2) + cos(w1))/2));
ex = @(w, w2)(z(w)*2/(1 - z(w2)) - (1  + z(w2))/(1 - z(w2)));
ew = @(x, w2)(z(x)*(1 - z(w2))/2 + (1 + z(w2))/2);
ex2x = @(w, w2)(log(ex(w, w2))/j);
ew2w = @(x, w2)(log(ew(x, w2))/j);

w2y = @(w, w2) (sqrt(1 - w2./(2.*tan(w/2))));
w2yb = @(w, wi) (sqrt((1 - wi(2)./(2.*tan(w./2)))/(1 - wi(1)./(2*tan(w./2)))));
w2y = @(w, wi) (sqrt((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1))));
w2y2 = @(w, wi) ((2.*tan(w./2) - wi(2))./(2*tan(w./2) - wi(1)));
y2w = @(z,wi)(2.*atan((wi(2) - z.^2.*wi(1))./(2.*(1 - z.^2))));
s2y = @(s,wi)(sqrt((2j.*tanh(s./2) + wi(2))./(2j.*tanh(s./2) + wi(1))));
z2y2 = @(z,wi)((2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
z2y_ = @(z,wi)(sqrt((2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1))));
y2z = @(y,wi)((2 + j.*wi(2) + y.^2.*(-2 - j.*wi(1)))./(2 - j.*wi(2) - y.^2.*(2 - j.*wi(1))));
ysq2z = @(ysq,wi)((2 + j.*wi(2) + ysq.*(-2 - j.*wi(1)))./(2 - j.*wi(2) - ysq.*(2 - j.*wi(1))));

z2y = @(z,wi)(-j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
w2x = @(w, wi) ((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1)));
y2z = @(y,wi)((2*j - wi(2) + y.*(2 + j*wi(1)))./(2*j + wi(2) + y.*(2 - j*wi(1))));
x2w = @(x,wi)(2.*atan((wi(2)*ones(size(x)) + wi(1).*x)./(2*ones(size(x)) + 2.*x)));

% For stopband transform
z2y = @(z,wi)(j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
w2x = @(w, wi) -((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1)));
y2z = @(y,wi)((2*j - wi(2) - y.*(2 + j*wi(1)))./(2*j + wi(2) - y.*(2 - j*wi(1))));
x2w = @(x,wi)(2.*atan((wi(2)*ones(size(x)) - wi(1).*x)./(2*ones(size(x)) - 2.*x)));
