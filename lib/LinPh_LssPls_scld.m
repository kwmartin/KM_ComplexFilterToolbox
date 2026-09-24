function H3 = LinPh_LssPls_scld(n, deltT, ap, fstp)
%   [_scld copy of LinPh_LssPls.m - rejects a collapsed prototype, keeps the best valid iteration]
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
    % LinPhFltr's deltT and the ripple fnd_gd_ripple measures on the
    % scaled filter are different quantities, so the loop below rescales
    % the request by deltT/deltT1. For n >= 7 that pushes the request past
    % what LinPhFltr can solve (about 1.2 for n = 7) and fsolve returns a
    % collapsed prototype: some poles jump to |s| of about 300 and the
    % group delay is no longer equi-ripple, yet the residual check passes.
    % The original LinPh_LssPls kept the last iteration regardless. Here a
    % prototype whose largest pole magnitude exceeds COLLAPSE_FCTR times
    % the first iteration's is rejected, the loop stops, and the valid
    % iteration whose measured ripple is closest to deltT is returned.
    COLLAPSE_FCTR = 5;
    deltT0 = deltT;
    pMax1 = [];
    bestErr = inf;
    for i=1:3
        [H1 T0] = LinPhFltr(n, deltT0, ap);
        H2 = equalGDLossPoles(H1, fstp);
        w = fndApFrq(H2, ap);
        H3i = scaleFltr(H2, 1.0/w);
        % plot_am_ph_gd(H4, [-1.5 1.5], 'b');
        % plot_crsps(H4,wp,ws,'b',[-10 10 -120 1]);
        [~, pH] = zpkdata(H3i, 'vector');
        pMax = max(abs(pH));
        if isempty(pMax1)
            pMax1 = pMax;
        elseif pMax > COLLAPSE_FCTR*pMax1
            fprintf(['LinPh_LssPls_scld: prototype collapsed at iteration %d ' ...
                '(deltT0 = %.4g, max |p| = %.4g vs %.4g) - keeping the best ' ...
                'earlier iteration\n'], i, deltT0, pMax, pMax1);
            break
        end
        [deltT1 deriv] = fnd_gd_ripple(H3i,[0 1])
        if abs(deltT1 - deltT) < bestErr
            bestErr = abs(deltT1 - deltT);
            H3 = H3i;
        end
        deltT0 = (deltT/deltT1) * deltT0;
    end

    a = 1;
