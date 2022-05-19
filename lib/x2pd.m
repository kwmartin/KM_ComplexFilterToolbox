function p = x2pd(x,wp)
%   w = x2pd(x,wp) is used to transform a frequency in the z-domain
%   back to the untransformed domain and returns e^jw.
%   wp is the two pass-band frequencies
%   which are pre-scaled to account for 2tanh(x/2) scaling
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
%   Ken Martin: 11/24/03
%   Revised: 10/20/18

p = (2 + j.*wp(2) + x.^2.*(-2 - j.*wp(1)))./(2 - j.*wp(2) - x.^2.*(2 - j.*wp(1)));
