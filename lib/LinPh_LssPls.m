function H3 = LinPh_LssPls(n, deltT, ap, fstp)
%   H = LinPhFltr(n, deltT, ap, az) returns an n'th order real low-pass equi-ripple
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
    deltT0 = deltT;
    for i=1:3
        [H1 T0] = LinPhFltr(n, deltT0, ap);
        H2 = equalGDLossPoles(H1, fstp);
        w = fndApFrq(H2, ap);
        H3 = scaleFltr(H2, 1.0/w);
        % plot_am_ph_gd(H4, [-1.5 1.5], 'b');
        % plot_crsps(H4,wp,ws,'b',[-10 10 -120 1]);
        [deltT1 deriv] = fnd_gd_ripple(H3,[0 1])
        deltT0 = (deltT/deltT1) * deltT0;
    end

  a = 1;
