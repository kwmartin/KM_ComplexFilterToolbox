function H = adaptP3(H, deltT)
%   [H2, deltT] = adaptP2(H) adapts the poles of a digital filter to correct the group delay
%   to be equiripple after being distorted by the bilinear transform
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
    dp2rq = @(dp) [real(dp(:)); imag(dp(:))];
    deltW = 1e-5*2*pi;
    updK = -0.02;
    
    [z, p, k] = sortZPK(H);
    a = angle(p);
    m = abs(p);
    %m = ones(size(m))*m(end);
    % m = sqrt(m); % increase Q to ensure we start with enough peaks
    m = m.^0.1;
    a1 = tan(1.05*a);
    % a1 = a;
    Np = length(a1);

    % Ensure the STARTING configuration already has enough independent
    % group-delay extrema (2*Np-1, the same threshold the main loop's
    % collision monitor below uses) before the Newton loop even begins.
    % Starting short makes the very first sens\Y solve rank-deficient,
    % which is how a "working" result can silently converge with several
    % poles collapsed together instead of ever tripping the in-loop
    % monitor (confirmed on dig_linPh_1_2_0b.m: 5 poles clustered within
    % ~0.04 of each other, p2p group delay 67.9 samples vs <1 for a
    % properly-resolved case -- and on dig_linPh_1_6_0.m/1_8_0.m, whose
    % ORIGINAL narrow-passband spec starts short by exactly this amount).
    %
    % Two starting heuristics are tried, each independently refined to
    % convergence (or INIT_MAX_ITERS attempts) by pairwise-nudging the
    % most at-risk adjacent pair apart (see refineExtremaCount below):
    % (1) the existing tan(1.05*a) angle warp, and (2) a more global even
    % redistribution of all Np angles across the same span. Keep
    % whichever FULLY-REFINED result ends up better. Trying only the
    % better STARTING point and refining once was tried first and found
    % to regress: dig_linPh_1_6_0.m's even-spacing start has more extrema
    % initially (11 vs tan-warp's 7) but its own pairwise-nudge
    % refinement plateaus at 12 of the 13 needed, while refining from the
    % WORSE tan-warp start (7) reaches the full 13 -- local refinement's
    % reachable plateau depends on which region of the search space it
    % starts in, not just the starting count. Running both refinements
    % fully and keeping the better final result avoids ever doing worse
    % than either heuristic alone.
    INIT_MAX_ITERS = 60;
    NUDGE_STEP = 0.02; % radians per attempt

    aEven = linspace(min(a1), max(a1), Np).';
    [p1_tan, count_tan] = refineExtremaCount(z, k, m, a1, Np, INIT_MAX_ITERS, NUDGE_STEP, 'tan-warp');
    [p1_even, count_even] = refineExtremaCount(z, k, m, aEven, Np, INIT_MAX_ITERS, NUDGE_STEP, 'even-spacing');
    if count_even > count_tan
        p1 = p1_even;
        bestCount = count_even;
        chosenLabel = 'even-spacing';
    else
        p1 = p1_tan;
        bestCount = count_tan;
        chosenLabel = 'tan-warp';
    end
    fprintf(['adaptP3: starting heuristics refined - tan-warp reached %d, ' ...
        'even-spacing reached %d, using %s (need %d)\n'], count_tan, ...
        count_even, chosenLabel, 2*Np-1);
    H1 = zpk(z, p1, k);
    wz = fndZeroCrs3(H1);
    if bestCount < 2*Np - 1
        fprintf(['adaptP3: could not reach %d starting extrema after both ' ...
            'refinements (best %d) - proceeding anyway.\n'], 2*Np-1, bestCount);
    end

    w1 = angle(p1);
    wrng = 1.2*[w1(1) w1(end)];
    fgd = wrng/(2*pi);
    w = wrng(1):deltW:wrng(2);
    % wz2 = fndZeroCrs2(H1,fgd); % works very well but 22.6 times slower
    Tz = p2T(H1, wz);
    %dT = mean(abs(diff(gdHz1(1:Np))));

    p = p1;
    gd1 = Tz(Np);
    % deltT = 0.01*gd1;
    gd2 = gd1 - deltT;
    % figure;
    hold on
    f = w./(2*pi);
    N=200;
    % Ceiling reduced from the original logspace(-2,-1,N) (max 0.1): the
    % escalating step was found to overshoot and drive poles back into
    % collision even from a starting configuration that already exceeded
    % the required extrema count (confirmed on dig_linPh_1_8_0.m: even-
    % spacing starts at 18 extrema, above the 17 needed, but the
    % escalating step still degrades it to 16 and halts, even with the
    % proactive proximity check above catching the same collisions no
    % earlier than the reactive one used to). A lower ceiling trades
    % iteration count for stability.
    uP = logspace(-2,-1.5,N);

    % Some poles can converge to (nearly) the same position - once that
    % happens, fndZeroCrs3 legitimately finds fewer genuine group-delay
    % extrema than there are free poles (each pole contributes 2 real
    % unknowns via plSens's real/imag columns), so the sens\Y solve
    % becomes rank-deficient and its minimum-norm solution has no reason
    % to pull the colliding poles apart again - a silent, unmonitored
    % degeneration confirmed via dig_linPh_1_2_0b.m: its "working" result
    % has 5 of its poles clustered within ~0.04 of each other in both
    % magnitude and angle. frozen tracks poles we've stopped updating in
    % response (mirroring place_polesdLP3.m's identical collision-freeze
    % pattern for the later stop-band stage); collisionIters counts
    % iterations since the last freeze where the system is still short an
    % extremum - if that doesn't resolve within COLLISION_MAX_ITERS, give
    % up with a clear error instead of silently returning a degenerate H.
    COLLISION_TOL = 1e-3;
    COLLISION_MAX_ITERS = 5;
    frozen = false(1, Np);
    collisionIters = 0;

    for i = 1:N
        H = zpk(z, p, k, 1);
        wz = fndZeroCrs3(H);
        Tz = p2T(H, wz);
        meanTz = mean(Tz);
        gd1 = meanTz + deltT/2;
        gd2 = meanTz - deltT/2;
        Y = setY2(Tz, gd1, gd2);

        freeIdx = find(~frozen);
        npFree = length(freeIdx);
        npts = length(wz);

        % Proactively freeze any free pole pair that has already drifted
        % within COLLISION_TOL, even if npts hasn't dropped below
        % threshold yet. Waiting for that symptom was found to be too
        % late: a starting configuration that comfortably meets the
        % required extrema count can still drift back into collision
        % over the course of this loop and fail regardless (confirmed on
        % dig_linPh_1_8_0.m: even-spacing starts at 18 extrema, above
        % the 17 needed, but the loop still degrades it to 16 and halts
        % -- checking proximity directly, every iteration, catches drift
        % before it becomes a shortfall instead of after).
        if npFree > 1
            [~, sortIdx] = sort(angle(p(freeIdx)));
            sortedFree = freeIdx(sortIdx);
            for m = 1:(length(sortedFree)-1)
                kA = sortedFree(m);
                kB = sortedFree(m+1);
                if abs(p(kB) - p(kA)) < COLLISION_TOL
                    fprintf(['adaptP3: poles %d and %d drifted to nearly the ' ...
                        'same position (%.4g%+.4gi, %.4g%+.4gi) - freezing ' ...
                        'pole %d\n'], kA, kB, real(p(kA)), imag(p(kA)), ...
                        real(p(kB)), imag(p(kB)), kB);
                    frozen(kB) = true;
                    freeIdx = find(~frozen);
                    npFree = length(freeIdx);
                    break
                end
            end
        end

        if npts + 1 < 2*npFree
            % Too few independent extrema for the current free-pole
            % count. Look for a newly-collided pair among the still-free
            % poles (sorted by angle, the natural 1-D ordering plSens/
            % fndZeroCrs3 already assume elsewhere in this file) and
            % freeze one of them.
            [~, sortIdx] = sort(angle(p(freeIdx)));
            sortedFree = freeIdx(sortIdx);
            for m = 1:(length(sortedFree)-1)
                kA = sortedFree(m);
                kB = sortedFree(m+1);
                if abs(p(kB) - p(kA)) < COLLISION_TOL
                    fprintf(['adaptP3: poles %d and %d converged to nearly the ' ...
                        'same position (%.4g%+.4gi, %.4g%+.4gi) - freezing ' ...
                        'pole %d\n'], kA, kB, real(p(kA)), imag(p(kA)), ...
                        real(p(kB)), imag(p(kB)), kB);
                    frozen(kB) = true;
                    break
                end
            end
            collisionIters = collisionIters + 1;
            if collisionIters > COLLISION_MAX_ITERS
                error('adaptP3:tooFewExtrema', ...
                    ['adaptP3: only found %d group-delay extrema for %d free ' ...
                    'pole(s) after freezing colliding poles for %d iterations ' ...
                    '- group-delay adaptation halted'], npts, npFree, ...
                    COLLISION_MAX_ITERS);
            end
            % Whether or not a new collision was found to freeze this
            % pass, retry next iteration rather than solving an
            % under-determined system.
            continue
        end
        collisionIters = 0;

        sens = plSens(p, wz);
        % Zero out (rather than remove) frozen poles' real/imag
        % sensitivity columns: plSens's last row encodes a mirror-pair
        % symmetry constraint across ALL np poles (column l paired with
        % np-l+1), so dropping just one side of a pair would corrupt
        % that structure. A zeroed column can't reduce the least-squares
        % residual, so sens\Y naturally assigns that pole's delta as
        % (near-)zero - equivalent to freezing it, without touching the
        % matrix shape.
        frozenIdx = find(frozen);
        sens(:, [frozenIdx, frozenIdx+Np]) = 0;
        dX = sens\Y;

        if any(~isfinite(dX)) || any(abs(dX) > 50)
            % Same two-part fix, and same underlying cause, as
            % place_polesdLP3.m's/place_polesdLP5.m's identical checks:
            % two free poles can drift close enough that their
            % sensitivity columns become nearly linearly dependent
            % (confirmed here: a "Matrix is singular to working
            % precision" warning right before this, on dig_linPh_1_6_0.m
            % -- close enough to make sens\Y produce a finite-but-huge or
            % outright non-finite dX, without being close enough to trip
            % either the proximity check above or the extrema-count
            % check). Reject the step and retry next iteration instead
            % of letting it corrupt p into a NaN/Inf zpk() crash.
            continue
        end

        dP = rq2dp(dX);
        p = p - uP(i)*dP;
        % Clamp any pole that crossed the unit circle back to a safe
        % radius -- same fix, and same confirmed positive-feedback
        % instability mechanism, as adaptP2.m's identical line (see its
        % comment there for the full explanation and the verified
        % before/after trace). Worse here than in adaptP2 in practice,
        % since this loop's escalating step size (uP, up to 0.1 vs
        % adaptP2's fixed 0.05) makes the initial unstable-crossing step
        % larger and the runaway faster.
        R_MAX = 0.995;
        tooBig = abs(p) > R_MAX;
        p(tooBig) = R_MAX * p(tooBig)./abs(p(tooBig));
        %T = p2T(H, w);
        %plot(f,T)
    end
    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w(:));
    figure;
    plot(f,gdH,'r','LineWidth',1);
    a = 1;
end

function [bestP1, bestCount] = refineExtremaCount(z, k, m, aInit, Np, maxIters, nudgeStep, label)
%   Pairwise-nudge refinement of a starting angle configuration aInit,
%   tracking the best (most group-delay extrema) configuration seen -
%   see adaptP3's own comments above its call to this function for the
%   full rationale.
    p1 = m.*exp(j*aInit);
    H1 = zpk(z, p1, k);
    wz = fndZeroCrs3(H1);
    bestCount = length(wz);
    bestP1 = p1;
    iter = 0;
    while bestCount < 2*Np - 1 && iter < maxIters
        iter = iter + 1;
        aCur = angle(p1);
        [~, srt] = sort(aCur);
        gaps = diff(aCur(srt));
        [minGap, worstIdx] = min(gaps);
        kA = srt(worstIdx);
        kB = srt(worstIdx+1);
        fprintf(['adaptP3 (%s): short %d extrema (found %d, best %d, need ' ...
            '%d) - separating poles %d and %d (gap %.4g rad), attempt %d\n'], ...
            label, (2*Np-1)-length(wz), length(wz), bestCount, 2*Np-1, kA, kB, ...
            minGap, iter);
        aCur(kA) = aCur(kA) - nudgeStep/2;
        aCur(kB) = aCur(kB) + nudgeStep/2;
        p1 = m.*exp(j*aCur);
        H1 = zpk(z, p1, k);
        wz = fndZeroCrs3(H1);
        if length(wz) > bestCount
            bestCount = length(wz);
            bestP1 = p1;
        end
    end
end
