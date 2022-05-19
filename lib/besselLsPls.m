function H3 = besselLsPls(n, ap, fstp)
%   H = besselLssPls(n, ap, az) returns an n'th order real low-pass equi-ripple
%   group delay filter with finite loss-poles in stop band.
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
    warning('off', 'Control:ltiobject:ZPKComplex');
    H1 = bessel_filt(n, [-1 1], ap);
    H2 = equalGDLossPoles(H1, fstp);
    w = fndApFrq(H2, ap);
    H3 = scaleFltr(H2, 1.0/w);
    % plot_am_ph_gd(H3, [-1.5 1.5], 'b');
    % plot_crsps(H3,wp,ws,'b',[-10 10 -120 1]);

    a = 1;
