%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function plot_crsps(H,wp,ws,colour,lim)
% PLOT_DRSPS(H) is used to plot the stopband and passband magnitude response
% of a discrete tranfer function H. w is a vector containing in order: lower
% passband frequency, upper passband frequency, lower stopband frequency,
% and upper stopband frequency.

w =[wp ws];
A = 20*log_rsps(H,j*w);
wdiff1 = max(ws) - min(ws);
wdiff2 = wp(2) - wp(1);

if nargin == 5
    if length(lim) ~= 4
        error('The specifications for plotting must be a vector of size 4');
    end
    x1 = lim(1);
    x2 = lim(2);
    y1 = lim(3);
    y2 = lim(4);
else
	x1 = w(3) - 1.5*wdiff1;
	x2 = w(4) + 1.5*wdiff1;
	y1 = 1.2*min(A);
	y2 = 1;
end

delta = (x2 - x1)/1e4;
s = x1:delta:x2;
h = 20*log_rsps(H,j*s);

subplot(2,1,1)
plot(s,h,colour)

axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')
subplot(2,1,2)
plot(s,h,colour)

x1 = w(1) - 0.05*wdiff2;
x2 = w(2) + 0.05*wdiff2;
y1 = max(A) + 5*A(1);
y2 = max(A) - 1.5*A(1);

axis([x1 x2 y1 y2])
title('Passband')
ylabel('dB')
xlabel('Frequency')
