function y = filterAllPass(fpT, data)
%   y = filterAllPass(fpT, data) filters data with a first-order all-pass
%   based on the bilinear approach. Set fpT equal to the desired frequency
%   where -90 degrees is desired.
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
    wpT = 2*tan(pi*fpT); % Apply frequency pre-distortion
    K = (1 - 2/wpT)/(1 + 2/wpT);
    A = [1, K];
    B = [K, 1];
    y = filter(B, A, data);
    a = 1;
    