function cndtn = condition(X0) % find condition number of removal X0
%   The contion number is based on the ratio of residues
%   Using this for a condition number is somewhat arbitrary, but usage
%   has found it's a good indication of how ill conditioned ladder
%   filter removals are
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
    tol = 2e-6;
    [n d] = tfdata(X0, 'v');
    [res, pls, rem] = residue(n, d);
    nmbs = [res; rem.'];
    abss = abs(nmbs(find(abs(nmbs) > tol))); % consider non-zero abs()'s
    if ~(min(abss) == 0)
        cndtn = max(abss)/min(abss);
    else
        cndtn = realmax;
    end
