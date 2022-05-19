function [lpOut, pks, diffs, diffs2] = AnlyzRcrd(rcrdNm, directory, cscFltr)
%   [Wlp, pks, diffs, diffs2] = AnlyzRcrd(rcrdNm) analyzes a binary record
%   specified by rcrdNm from directory for its heart beat. The filter bank
%   is based on prototype filter cscFltr.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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

    v = setV([0 5 10 25 70 80],[0 4 8.5 25 35 0]);
    flNm = strcat(directory, rcrdNm, '.bin');
    x1 = RdArry(flNm);
    x2 = preFltrData(x1,0.16,0.0008,2);
    x3 = simCscdFltrBnk(cscFltr, x2, 1/256);
    xp = x3.*conj(x3);
    x4 = x3*v;
    x5 = x4.*conj(x4);
    x6 = x5./mean(x5);
    lpOut = lpFltr(x6,0.0125); % This number is critical ; we probably need to adapt it
    [pks,locs,wdths,hts, diffs, diffs2, tgs] = xtrctB2B(lpOut);

    a = 1;