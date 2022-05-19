function y = anlyzData(xin,cscdLP,cscdHP,cscdBP,delta_f)
%   y = anlyzData(xin,cscdLP,cscdHP,cscdBP,delta_f) smooths, and analyzes ECG signals
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
    ylp = cscdLP.sim(xin, 0);
    ydcm = subSmpl(ylp,4);
    yhp = cscdHP.sim(ydcm, 0);
    % ylp = cscdLP.sim(yhp, 0);
    % ydcm = subSmpl(ylp,4);
    % xin = ydcm;
    xin = yhp;
    Out = simCscdFltrBnk4(cscdBP, xin, delta_f);
    y = sum(abs(Out));
    a = 1;