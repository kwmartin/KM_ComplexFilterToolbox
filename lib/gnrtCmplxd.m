function X = gnrtCmplxd(frq, npts, dPh)
%   X = gnrtCmplxd(frq, npts, dPh)
%   returns a unit amplitude cos(2 * pi * f0 .* (0:f0:f*(npts - 1) + dPh)
%   + j * (2 * pi * f0 .* (0:f0:f*(npts - 1) + dPh)
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

    wf = 2*pi*frq;
    t = (0:(npts-1))';
    X = exp(1j*(t(:).*wf + dPh));
    a = 1;
    
