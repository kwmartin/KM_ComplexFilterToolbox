function [rts2] = cleanRoots(rts, tol)
%   rts2 = cleanRoots(rts, tol) set any real or imaginary parts of vector rts
%   have an abs() value less than tol to 0. tol defaults to 1e-5. Components with
%   absolute values larger than tol are unchanged.
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

    if nargin < 2
        tol =  1e-5;
    end

    rtsr = real(rts);
    rtsr(find(abs(rtsr) < tol)) = 0;
    rtsi = imag(rts);
    rtsi(find(abs(rtsi) < tol)) = 0;
    rts2 = rtsr + rtsi*j;
