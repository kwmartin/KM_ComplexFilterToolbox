function [fdb, fref_db] = plot_lddr(H, lddr,wp,ws,colour,lim)
%   Plot the frequency response of a ladder filter object
%   wp: passband vector, ws: stopband frequencies, lim: [x1 x2 y1 y2]
%   limits for plotting
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2018  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

hndl = figure('Position',[200 200 600 600]);
w =[wp ws];
wdiff1 = max(ws) - min(ws);
wdiff2 = wp(2) - wp(1);

if nargin < 7
    R2 = 1;
end

if nargin > 5
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
  y1 = -120;
  y2 = 2;
end

%delta = (x2 - x1)/10e3;
delta = wdiff2/5000;
%delta = (x2 - x1)/10;
s = x1:delta:x2;
hdb = 20*log_rsps2(H,j*s);

N = length(s);
%for i=1:length(s)
%  [V0(i), I0(i)] = lddr.freqEval(s(i));
%end

n1 = int32(N*(wp(1) - x1)/(x2 - x1));
n2 = int32(N*(wp(2) - x1)/(x2 - x1));

[V0, I0] = lddr.freqEval(s);
%fgn = abs((2.0)./V0)/sqrt(R2);
fgn = abs((1.0)./V0);
fdb=20*log10(abs(fgn));

nmid = floor((n1 + n2)/2);
%fref_db = fdb(nmid);
fref_db = max(fdb);
fdbr = fdb - fref_db;
%href_db = hdb(nmid);
href_db = max(hdb);
% add a bit so we can see hdb
hdbr = hdb - href_db + 0.001;
pbMin = min(hdbr(n1:n2));

subplot(2,1,1)
plot(s,hdbr,'r')
hold on
plot(s,fdbr,colour)
hold off

axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')
subplot(2,1,2)
plot(s,hdbr,'r')
hold on
plot(s,fdbr,colour)
hold off

x1 = w(1) - 0.05*wdiff2;
x2 = w(2) + 0.05*wdiff2;
y1 = href_db + pbMin - 0.05;
y2 = href_db + 0.05;

axis([x1 x2 y1 y2])
title('Passband')
ylabel('dB')
xlabel('Frequency')
