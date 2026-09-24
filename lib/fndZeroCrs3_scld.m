function wz = fndZeroCrs3_scld(H, wp)
%   [_scld copy of fndZeroCrs3.m - drops the extremum at Nyquist (w = +-pi)]
%   indc = fndZeroCrs3_scld(H, wp) finds the zero-crossings of the derivative function used in
%   finding peaks for adapting the poles to get equiripple group delay of a digital filter
%   Inputs are the frequency vector (in Hz), the derivatives at those frequencies, and the
%   pole positions; the angles of the poles are used to determine the starting and endpoints
%
%   The search range is the passband wp extended past each edge by a
%   margin sized from an actual initial analysis, not a fixed fraction of
%   the passband width: scan progressively wider windows (starting at 1x
%   the passband width, doubling) until no group-delay extremum sits near
%   the current window's edge, then use the outermost extremum actually
%   found, plus a 20% buffer, as the margin. A fixed-fraction margin (this
%   file's first fix attempt used 0.1x passband width) was found
%   empirically to be far too small in general - confirmed on a 7-pole
%   filter (EqualFltr_1_6_0.m) whose genuine equiripple extent reached
%   ~3.5x the passband width, where a 0.1x margin found only 5 of the 13
%   real extrema, with the missing ones sitting essentially at the search
%   window's own edge - a signature that should have been (and wasn't,
%   initially) caught by checking whether found extrema cluster near the
%   window boundary.
%
%   Before this fix: a hardcoded [-0.45 0.45]*2*pi spanning nearly the
%   whole spectrum regardless of passband width, which for a narrow,
%   near-DC passband swamped the real passband extrema with irrelevant
%   stop-band structure and made adaptP3's group-delay-extrema count come
%   out badly short (a different failure mode than the fixed-fraction
%   margin's, but the same underlying problem: the search range needs to
%   track the filter's actual behavior, not a number disconnected from it).
%
%   The search window is clamped to +-pi: z=e^{jw} is periodic with
%   period 2*pi, so a window that overshoots +-pi doesn't reach new
%   information - it aliases back onto frequencies already inside
%   [-pi,pi], and AnlzDH/zci then "find" spurious/wrapped crossings
%   there instead. Confirmed on examples/dig_linPh_1_8_0.m (Np=9,
%   wp=[-0.005 0.005], width=0.01): its genuine equiripple extent needs
%   the full 64x margin cap, pushing the unclamped window to
%   2*pi*[-0.645,0.645] = [-4.05,4.05] rad, well past +-pi - the
%   resulting wz included values as far out as -3.516 and 2.767 with no
%   mirrored counterpart, clearly not genuine passband-relative extrema.
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

    [z, p, k] = sortZPK(H);
    deltW = 1e-5*2*pi;
    zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);

    width = wp(2) - wp(1);
    % Locate pass: coarser grid, progressively wider window, doubling
    % from 1x the passband width, until no crossing sits within a few
    % grid points of the window's own edge (i.e. widening further stops
    % turning up new extrema) or the cap is hit. The cap (64x) is a
    % judgment call - generous enough for every case tried so far, but
    % nowhere near the old near-whole-spectrum search, so it still
    % shouldn't reach unrelated stop-band structure far from the passband.
    coarseDeltW = 1e-4*2*pi;
    marginMult = 1;
    MAX_MARGIN_MULT = 64;
    NYQUIST = pi; % z=e^{jw} is periodic with period 2*pi - a window past
                  % +-pi aliases back onto frequencies already covered,
                  % not new information (see file header comment).
    outermost = width/2; % fallback if even mult=1 finds nothing
    while true
        wTestRaw = 2*pi*[wp(1) - marginMult*width, wp(2) + marginMult*width];
        wTest = [max(wTestRaw(1), -NYQUIST), min(wTestRaw(2), NYQUIST)];
        atBoundary = (wTest(1) <= -NYQUIST) && (wTest(2) >= NYQUIST);
        wGrid = wTest(1):coarseDeltW:wTest(2);
        [~, ~, ~, ~, dTdWTest] = AnlzDH(H, wGrid);
        idxTest = zci(dTdWTest);
        nearEdge = any(idxTest <= 3) | any(idxTest >= length(wGrid) - 3);
        if ~isempty(idxTest)
            % For each crossing, how far PAST the nearest passband edge it
            % sits (0 if inside [wp(1),wp(2)]) - not its distance to both
            % edges, which would overestimate for a crossing near either
            % edge by conflating it with the (much larger) distance to
            % the far edge.
            wc = wGrid(idxTest);
            distPast = max(0, max(2*pi*wp(1) - wc, wc - 2*pi*wp(2)));
            outermost = max(max(distPast)/(2*pi), outermost);
        end
        if atBoundary || ~nearEdge || marginMult >= MAX_MARGIN_MULT
            break
        end
        marginMult = marginMult * 2;
    end
    % Final margin: the outermost extremum actually found, plus 20% ("a
    % bit extra") - not a fraction of passband width disconnected from
    % what's actually there. Still clamped to +-pi for the same reason
    % as the locate pass above.
    margin = 1.2 * outermost;
    wrng = 2*pi*[wp(1) - margin, wp(2) + margin];
    wrng = [max(wrng(1), -NYQUIST), min(wrng(2), NYQUIST)];
    w = wrng(1):deltW:wrng(2);

    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w);
    indc = zci(dTdW);
    doubleIndc = find(diff(indc) == 1);
    % If dTdW has a zero value, it will give two values in indc; delete the
    % second one
    if ~isempty(doubleIndc)
        indc(doubleIndc+1) = [];
    end

    % A candidate pole configuration can have zero group-delay extrema
    % within this (now properly narrow, passband-scoped) window - the old
    % near-whole-spectrum range rarely hit this since it was wide enough
    % to almost always contain something. indc(end) on an empty indc would
    % otherwise crash here ("Array indices must be positive integers").
    if isempty(indc)
        wz = [];
        return
    end

    if indc(end) == length(w) indc(end) = []; end

    %dTdW2 = gltchRmv(dTdW);
    % dTdW2 = medfilt1(dTdW);
    f = w./(2*pi);
    % indc = fndZeroInd(w,dTdW2,p);
    w2 = w(indc + 1);
    w1 = w(indc);
    dd2 = dTdW(indc + 1);
    dd1 = dTdW(indc);
    wz = w1 - dd1.*(w2 - w1)./(dd2 - dd1);
    % Drop the group-delay extremum at Nyquist (w = +-pi). It is found
    % whenever the search window above widens all the way to +-pi, is
    % reported twice (once at each end of the window) and has a tiny group
    % delay far below the passband's. Keeping it inflated the ripple
    % measure in dsgnEquiRplGD and gave adaptP3 more extrema than the
    % 2*Np-1 its Newton system expects. The tolerance is looser than one
    % fine grid step because wz is interpolated between grid points.
    NYQUIST_TOL = 1e-3;
    wz = wz(abs(wz) < NYQUIST - NYQUIST_TOL);

    a=1;