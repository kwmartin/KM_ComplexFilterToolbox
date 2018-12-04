function [yout, aprm] = horner(a,x)
% Horner's method; a(1) is coefficient of x^(n-1)
a = a(:).'; % make z a row vector
n = length(a);
y = a(1).*ones(length(x), 1);
aprm = y;
for j = 2:n-1
    y = y.*x + a(j);
    aprm = aprm.*x + y;
end
y = y.*x + a(n);
yout = y;