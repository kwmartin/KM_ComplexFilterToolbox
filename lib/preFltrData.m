function xout = preFltrData(xin,fLp,fHp,Ndcm)
%   y = anlyzData(xin,fLp,fHp,Ndcm) filter data with 5'th order low-pass
%   having 3dB frequency equal to fLp (in Hz), decimate by Ndcm, and high-
%   filter with cut-off frequency equal to fHp in Hz.
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
    xin = xin - mean(xin);
    [xhp cscdHp] = hpFltr(xin,fHp);
    [xlp cscdLp] = lpFltr(xhp,fLp);

    RootDir = getenv('CMPLXROOT');
    if isempty(RootDir)
        setenv('CMPLXROOT', cd);
        RootDir = getenv('CMPLXROOT');
    end
    
    % cscd2Yml(cscdHp, strcat(RootDir, '/juliaFiles/LpFlt/Filters/cscdHp', '.yml'));
    % cscd2Yml(cscdLp, strcat(RootDir, '/juliaFiles/LpFlt/Filters/cscdLp', '.yml'));

    xout = subSmpl(xlp,Ndcm);
    a = 1;