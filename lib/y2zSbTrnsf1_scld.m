function Hz = y2zSbTrnsf1_scld(Hy,fp)
%   [_scld copy of y2zSbTrnsf1.m - simpl tolerance scaled to the band width; see ScldGD.md section 10]
%   Hz = y2zSbTrnsf1(Hy,fp) transforms a continuous-time model in the y domain
%   to the discrete-time z domain using a conformal transform and plots
%   the magnitude response. This version is intended for improving accuracy
%   when designing equi-ripple filters. It does not use the square-root
%   function. It is intended for stop-band transforms
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
    warning('off', 'Control:ltiobject:TFComplex');
    warning('off', 'Control:ltiobject:ZPKComplex');

    wp = 2*tan(fp*pi);
    Hz = y2zSb(Hy,wp);
    hfp1 = rspsd(Hz, j*2*pi*fp(1));
    Hz.K = Hy.K/hfp1;
    % simpl's absolute 1e-6 tolerance made the pole pairs of passbands
    % narrower than about 1e-6 cycles real; scale it with the band (the
    % same as before for bands wider than about 1.6e-4 cycles).
    Hz = simpl(Hz, min(1e-6, 1e-3*2*pi*(fp(2) - fp(1))));
    a=1;
