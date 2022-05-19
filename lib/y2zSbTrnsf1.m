function Hz = y2zSbTrnsf1(Hy,fp)
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
    Hz = simpl(Hz);
    a=1;
