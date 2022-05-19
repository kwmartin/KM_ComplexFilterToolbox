function out = simCscdRspns(cscd, fShft, ylim)
% out = simCscdRspns(cscd fShft) simulates the impulse response of a
% cascade filter and plots the magnitude fft of the output
% fShft is an optional frequency shift. It generates an 8182x1 impulse
% input.
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

    xin = zeros(8192,1);
    xin(1) = 1;

    A = {};
    B = {};
    C = {};
    D = {};
    for i = 1:cscd.size
        sys = cscd.sctns(i).sys;
        [a b c d] = ssdata(sys);
        A{i} = a;
        B{i} = b;
        C{i} = c;
        D{i} = d;
    end

    out = simBiquad(A, B, C, D , xin, fShft);
    figure;
    dB = plotRspnsd(out, ylim);
