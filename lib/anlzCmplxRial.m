function Hw = anlzCmplxRial(wp, w, G)
%   Finds the response of a resonator in a loop filter with resonant
%   frequencies given in wp (in radians) at frequencies w (in radians)
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
    p = exp(j*wp);
    w = w(:);
    h = @(p, w)(p./(exp(j*w) - p + 5*eps));
    N = length(wp);
    Hw = zeros(length(w),N);
    
    for i = 1:N
        denom = 0;
        p2 = p;
        p2(p2 == p(i)) = [];
        hi = h(p(i),w);
        for k = 1:N-1;
            denom = denom + h(p2(k),w)./hi;
        end
        denom = denom + 1 + 1./(G.*hi);
        Hw(:,i) = 1./denom;
    end
    a = 1;
