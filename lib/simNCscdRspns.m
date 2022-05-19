function simNCscdRspns(cscd, fShft, ylim, N)
% simNCscdRspns(cscd fShft) simulates N adkacent impulse responses of a
% cascade filter and plots the magnitude fft of the output
% fShft is the amount each filter is shifted. N adjacent responses are
% plotted
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

    figure
    hold
    out = simCscdRspns(cscd, 0, ylim);
    outSm = out;
    for i = 1:N-1
        out = simCscdRspns(cscd, i*fShft, ylim);
        % outSm = outSm + (j.^1)*out;
        outSm = outSm + out;
    end
    dB = plotRspnsd(outSm, ylim);
    a = 1;
