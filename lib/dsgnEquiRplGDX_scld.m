function [H, p, px, wp, ws, as] = dsgnEquiRplGDX_scld(p,px,wp,ws,as,Ap,Ordr,sclFctr,shftFctr,deltGD)
%   [_scld copy of dsgnEquiRplGD.m - calls LinPh_LssPls_scld, fndZeroCrsX_scld and adaptP3X_scld]
% H = dsgnEquiRplGDX_scld(p,px,wp,ws,as,Ap,Ordr,deltGD) designs a complex digital filter
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
    H1 = LinPh_LssPls_scld(Ordr, deltGD, Ap, 3); % design continous prototype
    % next we transform to a digital filter using the bilinear transform,
    % this distorts the equi-ripple group delay
    [p, px, wp, ws, as, H2] = cont2Digital(H1, p, px, wp, ws, as, sclFctr, shftFctr);
    % shift back to 0 temporarilly
    H3 = freq_shiftd(H2, shftFctr);
    % now correct the distorted equi-ripple group delay; this distorts the
    % equi-ripple stop-band. wp3 is wp shifted the same way H3 was (H3 is
    % at a different frequency location than the wp returned above), so
    % adaptP3X_scld/fndZeroCrsX_scld search around H3's actual passband.
    wp3 = wp + shftFctr;

    % Check group-delay extrema BEFORE calling adaptP3X_scld: how many are
    % there, and how close to equi-ripple already? adaptP3X_scld is only meant
    % to correct group delay that the bilinear transform has genuinely
    % distorted - calling it unconditionally can make things worse when
    % it's not needed (confirmed on EqualFltr_1_6_0.m: the pre-adaptP3X_scld
    % group delay was already at 10.2% p2p/mean ripple with a clean
    % alternating extrema pattern, and adaptP3X_scld's own pole-angle-warping
    % search degrades that starting point before it tries to fix
    % anything). MIN_EXTREMA_TO_ASSESS=2 and RIPPLE_SKIP_THRESHOLD=0.10
    % are this session's own judgment calls (2 is the minimum needed to
    % even compute a p2p/mean ripple figure; 0.10 is the user-specified
    % skip threshold) - verify empirically on other cases, not just this
    % one.
    MIN_EXTREMA_TO_ASSESS = 2;
    RIPPLE_SKIP_THRESHOLD = 0.10;

    wzPre = fndZeroCrsX_scld(H3, wp3);
    if length(wzPre) < MIN_EXTREMA_TO_ASSESS
        error('dsgnEquiRplGDX_scld:tooFewExtrema', ...
            ['dsgnEquiRplGDX_scld: only found %d group-delay extrema in the ' ...
            'passband (need at least %d to assess equi-ripple error) - ' ...
            'cannot proceed'], length(wzPre), MIN_EXTREMA_TO_ASSESS);
    end
    [~, ~, gdPre] = AnlzDH(H3, wzPre(:));
    ripplePre = (max(gdPre) - min(gdPre)) / mean(gdPre);

    if ripplePre < RIPPLE_SKIP_THRESHOLD
        fprintf(['dsgnEquiRplGDX_scld: group delay already within %.1f%% of ' ...
            'equi-ripple (%.2f%%) - skipping adaptP3X_scld\n'], ...
            100*RIPPLE_SKIP_THRESHOLD, 100*ripplePre);
        H4 = H3;
    else
        % adaptP3X_scld can itself fail outright (e.g. it can't find enough
        % starting extrema for its own internal Newton loop) - a failure
        % is a worse outcome than not touching the poles at all, so treat
        % it the same as "adaptP3X_scld made things worse" and revert.
        try
            H4 = adaptP3X_scld(H3,0.1,wp3);
            wzPost = fndZeroCrsX_scld(H4, wp3);
            revert = length(wzPost) < MIN_EXTREMA_TO_ASSESS;
            if ~revert
                [~, ~, gdPost] = AnlzDH(H4, wzPost(:));
                ripplePost = (max(gdPost) - min(gdPost)) / mean(gdPost);
                revert = ripplePost >= ripplePre;
            end
            if revert
                if length(wzPost) < MIN_EXTREMA_TO_ASSESS
                    fprintf(['dsgnEquiRplGDX_scld: adaptP3X_scld''s output has too few ' ...
                        'extrema to assess (%d) - reverting to pre-adaptP3X_scld ' ...
                        'poles\n'], length(wzPost));
                else
                    fprintf(['dsgnEquiRplGDX_scld: adaptP3X_scld made group-delay ripple ' ...
                        'worse (%.2f%% -> %.2f%%) - reverting to pre-adaptP3X_scld ' ...
                        'poles\n'], 100*ripplePre, 100*ripplePost);
                end
                H4 = H3;
            end
        catch ME
            fprintf(['dsgnEquiRplGDX_scld: adaptP3X_scld failed (%s) - reverting to ' ...
                'pre-adaptP3X_scld poles\n'], ME.message);
            H4 = H3;
        end
    end
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