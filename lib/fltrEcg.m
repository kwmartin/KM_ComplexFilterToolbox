function xout = fltrEcg(xin,khp,klp)
%   xout = fltrEcg(xin,khp,klp) is a bandpass filter for ECG signals composed of
%   a third-order high-pass and a fifth order lowpas with one finite
%   transmission zero. The upper stop-band loss is about 55dB/
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
    x1 = hpFltr3rdOrdr(xin,khp);
    xout = lpFltr5thOrdr(x1,klp);
    a = 1;