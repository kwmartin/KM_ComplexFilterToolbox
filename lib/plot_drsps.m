function [ax1, ax2] = plot_drsps(H,fp,colour,lim)
%   Replace this function with plot_dam() where lim has only [y1 y2]
%   PLOT_DRSPS(H) is used to plot the stopband and passband magnitude response
%   of a discrete tranfer function H. fp is the passband freqs. in Hz.
%   colour might be 'b', 'r', or 'g', as examples. lim specifies
%   plot the y axis limits: [y1 y2].
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
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

    [zd pd kd] = zpkdata(H);
    b = poly(zd{1});
    a = poly(pd{1});
    A = db(kd.*freqz(b,a,2*pi*[fp -0.5 0.5]));
    w = -0.5:1e-6: 0.5;
    s = 2*pi*w;
    x2n=@(x)int64(length(w)*(x + 0.5));
    % h=kd.*freqz(b,a,s);
    % dbH = db(h);
    [dbH h] = log_rspsd(H,j*s);
    fig = figure('Position',[500 300 500 600]);
    ax1 = subplot(2,1,1);
    plot(s./(2*pi),dbH,colour,'LineWidth',1)

    if length(lim) ~= 2
        error('The specifications for plotting must be a vector of size 2');
    end
    x1 = -0.5;
    x2 = 0.5;
    y1 = lim(1);
    y2 = lim(2);

    N = length(s);
    n1 = x2n(fp(1));
    n2 = x2n(fp(2));
    pbMin = min(dbH(n1:n2));

    axis([x1 x2 y1 y2])
    title('Magnitude Gain')
    ylabel('dB')
    xlabel('Frequency')
    ax2 = subplot(2,1,2);
    plot(s./(2*pi),dbH,colour,'LineWidth',1)

    wdiff = fp(2) - fp(1);
    x1 = fp(1) - 0.05*wdiff;
    x2 = fp(2) + 0.05*wdiff;
    mxH = db(max(h));
    y1 =  + pbMin - 2.0;
    y2 = max(dbH) + 1.0;

    axis([x1 x2 y1 y2])
    title('Passband')
    ylabel('dB')
    xlabel('Frequency')
