function H4 = equiGdDigital(p,px,ni,wp,ws,as,Ap,deltGD, useWs)
%   H = equiGdDigital(p,px,ni,wp,ws,as,Ap,deltGD, useWs) Design discrete TF
%   having equi-ripple group delay and stop-band attenuation
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

    % Matlab doesn't really support complex system objects. We work around
    % this limitation and therefore turn off warnings.
    warning('off', 'Control:ltiobject:TFComplex');
    warning('off', 'Control:ltiobject:ZPKComplex');

    ws1 = max(ws(ws < wp(1)));
    ws2 = min(ws(ws > wp(2)));
    if any((p < wp(1)) & (p > ws1)) | any((p > wp(2)) & (p < ws2))
        error('A moveable pole is in the transition region');
    elseif any((px < wp(1)) & (px > ws1)) | any((px > wp(2)) & (px < ws2))
        error('A fixed pole is in the transition region');
    end

    [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as);

    np = length(p);
    Ordr = ni + np;
    [H1 T0] = LinPhFltr(Ordr, 0.01, Ap); % design continous prototype
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
    H2 = adaptP2(H2,deltGD);
    H2.k = H2.k/(abs(freqresp(H2,0)));

    p1 = H2.z{1};
    p1 = p1((p1 + 1) < 1e-7);
    if length(p1) ~= ni + np
        error('There should be %d zeros',ni + np);
    end
    p2 = exp(2*pi*p*j);
    py = [-ones(ni,1); p2.'];
    py = sortImag(py);
    H3 = zpk(py, H2.p{1}, H2.k);
    if useWs
        H4= place_polesdLP5(H3,wp,[ws1 ws2]);
    else
        H4= place_polesdLP5(H3,wp);
    end

    a = 1; % always included as a place to put a break point.
