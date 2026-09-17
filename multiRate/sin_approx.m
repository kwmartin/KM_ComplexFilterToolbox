function [Approx_Sinusoid, Error] = sin_approx(data,freq,npts)
% [Approx_Sinusoid, Error] = sin_approx(data,freq,npts)
% This function matches a sinusoid to the input data in a least-mean-
% squared manner. The sampling time is assumed to be 1 second. Thus,
% the input data is assumed to be A sin(2 pi freq n) + B cos(2 pi freq n)
% where freq is fsignal/fsample. If npts is specified then npts must be
% less than length(data) and the last npts of data is used. This is useful
% in getting rid of the initial transients of linear systems.
%
data = data(:);
%
if nargin < 3
	npts=length(data);
else
	n=length(data);
	data=data(n-npts+1:n,1);
end
% The frequency increment
inc = 2*pi*freq;
%
% The frequency vector
w = (inc:inc:inc*npts)';
%
% The data input is matched to a weighted sum of a Cos and Sin vector
Sin = sin(w);
Cos = cos(w);
e = Cos'*Cos;
f = Sin'*Cos;
g = Sin'*Sin;
Det = e*g - f*f;
In_Phase = Sin'*data;
Quad_Phase = Cos'*data;
A = (In_Phase*e - Quad_Phase*f)/Det;
B = (Quad_Phase*g - In_Phase*f)/Det;
Approx_Sinusoid = A*Sin + B*Cos;
Error = data - Approx_Sinusoid;
aa=0;
