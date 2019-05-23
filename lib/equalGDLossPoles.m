function H = equalGDLossPoles(H1, ws, ap)
%   H = equalGDLossPoles(es) adds finite loss poles to linear phase filter
%   Normally H will have a passband edge of 1 and ws is the stop band frequency
%   The new transfer function H and the stop-band loss As (in dB) are returned.
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

    s2w = @(s)sqrt(1 + s.^2/ws^2);
    w2s = @(w) ws*sqrt(w.^2 - 1);
    invSq = @(w) ws^2 * (w2 - 1);

    [z p k] = zpkdata(H1, 'vector');
    p2 = -s2w(p);
    ply = poly(p2);
    plev = getEven(ply);
    plod = getOdd(ply);
    plod(end) = [];
    f2 = polyval(plod, 1)^2;
    e2 = polyval(plev, 1)^2;
    pE = roots(plev);

%    for i = 1:2:length(pE)-1
%        pEsq((i+1)/2) = pE(i)*pE(i+1);
%    end
%    zsSq = invSq(pEsq);
%    for i = 1:length(zsSq)
%        zs(2*i - 1) = sqrt(zsSq)*j;
%        zs(2*i) = -sqrt(zsSq)*j;
%    end
    zs = w2s(pE);
    zs = abs(imag(zs))*j;
    for i=2:2:length(zs);
        zs(i) = -zs(i);
    end
    H = zpk(zs, p, 1);
    H.k = H.k/evalfr(H, 0);
    a=1;