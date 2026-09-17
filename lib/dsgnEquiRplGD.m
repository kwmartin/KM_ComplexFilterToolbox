function [H, p, px, wp, ws, as] = dsgnEquiRplGD(p,px,wp,ws,as,Ap,Ordr,sclFctr,shftFctr,deltGD)
% H = dsgnEquiRplGD(p,px,wp,ws,as,Ap,Ordr,deltGD) designs a complex digital filter
% havine equi-ripple group delay and finite loss-poles with equi-loss
% attenuation in the stop band. The final filter uses sclFctr and shftFctr
% to produce a complex filter
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

    % First we find a continous-time prototype filter with pass-band at -1
    % to 1 rad having equi-ripple group delay and finite loss-poles
    H1 = LinPh_LssPls(Ordr, 0.15, Ap, 3); % design continous prototype
    % next we transform to a digital filter using the bilinear transform,
    % this distorts the equi-ripple group delay
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
    % shift back to 0 temporarilly
    H3 = freq_shiftd(H2, shftFctr);
    % now correct the distorted equi-ripple group delay; this distorts the
    % equi-ripple stop-band
    H4 = adaptP3(H3,0.1);
    % now shift back to the desired passband frequency; this is a complex
    % frequency shift
    H2 = freq_shiftd(H4, -shftFctr);
    % fix the gain to be unity at dc
    H2.k = H2.k/(abs(freqresp(H2,0)));
    % now adapt the loss poles so we again have an equi-ripple stop band;
    % this is done using a conformal transform that places the stop-band
    % between 0 and j*Inf.
    H = place_polesdLP3(H2,wp); % H is returned
    a = 1;