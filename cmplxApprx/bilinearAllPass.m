function h = bilinearAllPass(fpT, f)
%   h = ldiAllPass(k, w) calculates the frequency response of a first-order
%   LDI all-pass having TF defined by k at w radians
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
    wpT = 2*tan(pi*fpT);
    w = 2*pi*f;
    T1 = 1 - 2/wpT;
    T2 = 1 + 2/wpT;
    T3 = T1/T2;
    exp_wT = exp(j*w);
    z_1 = exp_wT.^-1;
    h = (T3 + z_1)/(1 + z_1*T3);
    a = 1;
    