function hgdx = hgdxMake(H,fgd)
%   hgdx = hgdxMake(H,fgd) transforms the group delay terms of a discrete-time model in the x domain
%   to the continuous-time x domain using a conformal transform.
%   This version is intended for improving accuracy
%   when designing equi-ripple filters. It does not use the square-root
%   function. fgd is currently the passband in z in Hz (later this may
%   change to rad.)
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

    h1p = H.p{1};
    z = tf('z',1);
    N = length(h1p);
    h = {};
    hgd = {};
    hgdx = {};
    for i = 1:N
        h{i} = zpk([0], h1p(i), 1, 1);
        hgd{i} = (h{i} + h{i}')*0.5;
        hgdx{i} = simpl(z2yTrnsfrm2(hgd{i},fgd));
    end

    a=1;
