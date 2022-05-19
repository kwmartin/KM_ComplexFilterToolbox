function [y cscdLP] = lpFltr(xin,flp)
%   [y cscdLP] = lpFltr(xin,flp) lowpass filters xin with a 5'th order
%   filter having a bandwidth of flp
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
    Wn = 2*flp; % Wn = 1 corresponds to f/fs = 0.5
    [zlp, plp, klp] = butter(5,Wn);
    hlp = zpk(zlp,plp,klp,1);
    cscdLP = mkCscdFltrD2(hlp, [-0.1 0.1]);
    y = real(cscdLP.sim(xin, 0));
    a = 1;