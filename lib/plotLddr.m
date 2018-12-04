function [fdb, fref_db] = plotLddr(lddr,wp,ws,colour,lim)
%   Plot the frequency response of a ladder object
%   uses the built in method lddr.freqEval(s) to evaluate
%   the frequency response. lim=[x1 x2 y1 y2] soecifies the axis for plotting
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

w =[wp ws];
wdiff1 = max(ws) - min(ws);
wdiff2 = wp(2) - wp(1);

if nargin > 4
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

delta = (x2 - x1)/25e3;
s = x1:delta:x2;

N = length(s);

[V0, I0] = lddr.freqEval(s);
fgn = abs((1.0)./V0);
fdb=20*log10(abs(fgn));

fref_db = max(fdb);
fdbr = fdb - fref_db;

hndl = figure('Position',[800 100 500 600]);
subplot(2,1,1)
plot(s,fdbr,colour)
axis([x1 x2 y1 y2])
title('Magnitude Gain')
ylabel('dB')
xlabel('Frequency')
subplot(2,1,2)
plot(s,fdbr,colour)

x1 = wp(1) - 0.05*wdiff2;
x2 = wp(2) + 0.05*wdiff2;
y1 = -3.5;
y2 = 0.5;

axis([x1 x2 y1 y2])
title('Passband')
ylabel('dB')
xlabel('Frequency')
