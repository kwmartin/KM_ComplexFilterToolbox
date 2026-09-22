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
    % H2 = adaptP3(H2,deltGD); % adaptP3's moving target (recomputed from
    % mean(Tz) every iteration) plus its escalating step size
    % (logspace(-2,-1,200), vs adaptP2's fixed 0.05) has no stability
    % safeguard and can drive poles well outside the unit circle -- for
    % dig_equiGd_1_12_0.m's parameters (deltGD=0.25), confirmed via direct
    % before/after pole check: H2 goes from max|pole|=0.87 (stable)
    % before this call to max|pole|=9.88, 9 of 13 poles unstable, after
    % adaptP3. adaptP2 is far better for this case (max|pole|=1.14, only
    % 4 poles marginally over 1) though still not a guarantee -- neither
    % function actually clamps pole magnitude. See dsgnDigitalFltr.m's
    % matching adaptP2/adaptP3 comment for the other call site with the
    % same underlying issue.
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
