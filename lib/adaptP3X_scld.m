function H = adaptP3X_scld(H, deltT, wp)
%   [_scld copy of adaptP3.m - finds group-delay extrema with fndZeroCrsX_scld (transformed variable)]
%   [H2, deltT] = adaptP3X_scld(H, deltT, wp) adapts the poles of a digital filter to correct the group delay
%   to be equiripple after being distorted by the bilinear transform.
%   wp is the passband, forwarded to fndZeroCrsX_scld so its search range
%   tracks the actual passband instead of a fixed fraction of the whole
%   spectrum.
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
    a = angle(p);
    mTrue = abs(p); % genuinely unmodified pole magnitudes - used only for
                     % the 'original' starting candidate below (see its
                     % own comment). Kept separate from the boosted m
                     % below after discovering (EqualFltr_1_6_0.m) that
                     % reusing the boosted m for the 'original' candidate
                     % silently distorted its radii too, defeating its
                     % whole purpose: |p|=0.998 boosted to |p|.^0.1=0.9998
                     % alone (independent of any angle warp) inflated
                     % this filter's peak group delay ~6-7x (near-unit-
                     % circle group delay scales roughly like 1/(1-|p|),
                     % and (1-|p|) shrank 10x from that boost).
    m = mTrue;
    %m = ones(size(m))*m(end);
    % m = sqrt(m); % increase Q to ensure we start with enough peaks
    m = m.^0.1; % boosts pole magnitude toward the unit circle - kept for
                % the tan-warp/even-spacing candidates below (apparently
                % needed on some filters for those angle-only heuristics
                % to reliably reach the extrema-count threshold), but
                % deliberately NOT applied to the 'original' candidate.
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
    % Three starting candidates are tried, each independently refined to
    % convergence (or INIT_MAX_ITERS attempts) by pairwise-nudging the
    % most at-risk adjacent pair apart (see refineExtremaCount below):
    % (1) the UNWARPED ORIGINAL angles a (the poles exactly as received,
    % before any perturbation), (2) the existing tan(1.05*a) angle warp,
    % and (3) a more global even redistribution of all Np angles across
    % the same span. Keep whichever FULLY-REFINED result is best.
    %
    % Candidate (1) was added after discovering (EqualFltr_1_6_0.m) that
    % the original, unwarped poles can ALREADY satisfy the 2*Np-1
    % threshold outright (13/13 here) with an excellent starting ripple
    % (10.3%, maxima within 0.02 of each other, minima within 0.01) -
    % but the tan-warp candidate ALSO reaches 13/13, and a plain
    % "highest count wins" comparison (the original two-candidate logic)
    % has no way to prefer the qualitatively better one, so it kept
    % picking tan-warp's badly-degraded 13/13 (~203% ripple) over the
    % original's already-excellent 13/13 - discarding a nearly-solved
    % problem and handing the main loop a much harder one instead.
    % Selection below is therefore by RIPPLE quality among candidates
    % that meet the threshold, not by raw count - count alone can't
    % distinguish a clean configuration from a barely-adequate, heavily
    % warped one that happens to hit the same number.
    %
    % Trying only the better STARTING point and refining once was tried
    % first (for the tan-warp/even-spacing pair) and found to regress:
    % dig_linPh_1_6_0.m's even-spacing start has more extrema initially
    % (11 vs tan-warp's 7) but its own pairwise-nudge refinement
    % plateaus at 12 of the 13 needed, while refining from the WORSE
    % tan-warp start (7) reaches the full 13 -- local refinement's
    % reachable plateau depends on which region of the search space it
    % starts in, not just the starting count. Running every candidate's
    % refinement fully and keeping the better final result avoids ever
    % doing worse than any single heuristic alone.
    INIT_MAX_ITERS = 60;
    NUDGE_STEP = 0.02; % radians per attempt

    aEven = linspace(min(a1), max(a1), Np).';
    candLabels = {'original', 'tan-warp', 'even-spacing'};
    candInits = {a, a1, aEven};
    candMags = {mTrue, m, m}; % 'original' uses the TRUE, unboosted
                               % magnitude - see mTrue's own comment above
    bestP1 = []; bestCount = -1; bestRipple = Inf; chosenLabel = '';
    candCounts = zeros(1, numel(candLabels));
    for ci = 1:numel(candLabels)
        [p1_c, count_c] = refineExtremaCount(z, k, candMags{ci}, candInits{ci}, Np, ...
            INIT_MAX_ITERS, NUDGE_STEP, candLabels{ci}, wp);
        candCounts(ci) = count_c;
        if count_c >= 2*Np - 1
            rip_c = candidateRipple(z, k, p1_c, wp);
        else
            rip_c = Inf;
        end
        % Prefer, in order: (1) meeting the threshold over not, (2) among
        % those that do, lowest ripple, (3) among those that don't,
        % highest count (unchanged from the original two-candidate rule,
        % for the case where nothing reaches the threshold).
        if isempty(bestP1)
            better = true;
        elseif isfinite(rip_c) && ~isfinite(bestRipple)
            better = true;
        elseif isfinite(rip_c) && isfinite(bestRipple)
            better = rip_c < bestRipple;
        elseif ~isfinite(rip_c) && ~isfinite(bestRipple)
            better = count_c > bestCount;
        else
            better = false;
        end
        if better
            bestP1 = p1_c; bestCount = count_c; bestRipple = rip_c; chosenLabel = candLabels{ci};
        end
    end
    p1 = bestP1;
    fprintf(['adaptP3X_scld: starting candidates refined - original reached %d, tan-warp ' ...
        'reached %d, even-spacing reached %d, using %s (need %d)\n'], candCounts(1), ...
        candCounts(2), candCounts(3), chosenLabel, 2*Np-1);
    H1 = zpk(z, p1, k);
    wz = fndZeroCrsX_scld(H1, wp);
    if bestCount < 2*Np - 1
        % Used to print a warning and fall through ("proceeding anyway"),
        % but nothing downstream actually tolerates fewer than Np extrema
        % - gd1 = Tz(Np) a few lines below indexes straight past the end
        % of a too-short Tz, crashing with an opaque "Array indices must
        % be positive integers" instead of a clear diagnostic. Raise a
        % real error here instead, so callers can catch it and revert to
        % their pre-adaptP3X_scld state (same principle as this file's own
        % in-loop collision-halt errors below).
        error('adaptP3X_scld:tooFewStartingExtrema', ...
            ['adaptP3X_scld: could not reach %d starting extrema after both ' ...
            'refinements (best %d) - cannot proceed'], 2*Np-1, bestCount);
    end

    % R_MAX clamps any pole that crosses the unit circle back to a safe
    % radius (see both loops below). Raised from an earlier 0.995: that
    % value was found to be too tight for legitimate high-Q, narrow-
    % passband designs whose required pole radii sit above it even when
    % perfectly stable - confirmed on EqualFltr_1_6_0.m, whose starting
    % poles (|p|=0.9998) already exceeded the old clamp before any
    % Newton step ran, so it fired unconditionally on iteration 1,
    % forcibly shrinking every pole's radius by ~0.005 - about 5x larger
    % than the actual Newton correction that iteration. 0.99999 still
    % catches genuine instability (any step that pushes a pole to/past
    % the unit circle) without corrupting legitimate near-unit-circle
    % designs.
    R_MAX = 0.99999;

    % Decide which Newton system to use. The standard system below
    % (plSens + setY2, alternating extrema toward two target levels,
    % squared up with plSens's single ad hoc mirror-constraint row) is
    % structurally near-singular whenever it's exactly at the extrema-
    % count threshold (rcond ~1e-15 confirmed on EqualFltr_1_6_0.m's
    % 13-extrema/7-pole case: the 13 group-delay rows alone are
    % guaranteed rank-deficient by 1, and the single constraint row only
    % weakly resolves that null direction). The reduced system
    % (adaptP3Reduced) fixes this by exploiting the poles' actual
    % independent real degrees of freedom (conjugate-pair symmetry -
    % guaranteed by construction for every current caller via
    % dsgnEquiRplGD.m's re-centering to baseband) and targeting only the
    % local maxima, each driven toward mean(minima)+deltaT with the
    % minima's own sensitivity to the same pole changes accounted for
    % (not a stale/self-referential target - an unanchored "maxima
    % toward their own floating mean" version was tried first and proven
    % exactly rank-deficient, matching a documented precedent in
    % examples/eqlzrD_peakNewtonStep.m). Validated on EqualFltr_1_6_0.m:
    % true overall peak-to-peak group delay reduced 5745->0.35 (>99.99%)
    % over 600 iterations with zero extrema-count collapse, versus the
    % standard system's near-immediate 13->1 collapse.
    %
    % This only applies when the reduced system's preconditions hold:
    % poles are exact conjugate pairs (within a numerical tolerance -
    % checkConjugatePairing), AND the found extrema split into exactly
    % Np maxima (matching the Np reduced real unknowns, giving a square
    % system). Not every filter satisfies the second condition -
    % confirmed on dig_linPh_1_8_0.m (Np=9), whose 9 poles split into two
    % structurally different clusters (a 5-pole near-DC group and a
    % 4-pole near-Nyquist group with much lower Q), producing 7 maxima /
    % 13 minima rather than the clean 9/8-ish split a single homogeneous
    % cluster gives - the reduced system's "one equation per pole"
    % premise doesn't hold there. Falls back to the standard system in
    % that case (and whenever poles aren't conjugate-paired), so every
    % filter this file has ever successfully designed keeps working via
    % its existing, proven path.
    isPaired = checkConjugatePairing(p1, Np);
    [~, ~, wzMinCheck, ~] = classifyExtrema(H1, wz);
    nMaxFound = length(wz) - length(wzMinCheck);
    useReduced = isPaired && (nMaxFound == Np) && ~isempty(wzMinCheck);

    if useReduced
        fprintf(['adaptP3X_scld: poles are conjugate-paired and %d maxima match %d poles - ' ...
            'using reduced Newton system\n'], nMaxFound, Np);
        try
            [H, w, f] = adaptP3Reduced(z, k, p1, Np, wp, deltT, R_MAX);
        catch ME
            % The reduced system's square shape depends on the Np-maxima
            % structure holding for the WHOLE run, not just the start -
            % it can still hit a structural change mid-loop that it
            % can't recover from (confirmed on dig_linPh_1_6_0.m: gains
            % an extra maximum partway through and doesn't settle back
            % to Np within the retry allowance). Falling all the way
            % back to the caller's own pre-adaptP3X_scld poles at that point
            % would discard the reduced system's real, if incomplete,
            % progress and any benefit adaptP3Standard could still
            % provide from the same starting point - so fall back to the
            % standard system here instead, same principle as this
            % file's own collision-halt-and-continue conventions
            % elsewhere.
            fprintf(['adaptP3X_scld: reduced Newton system failed (%s) - falling back to ' ...
                'standard Newton system\n'], ME.message);
            [H, w, f] = adaptP3Standard(z, k, p1, Np, wp, deltT, wz, R_MAX);
        end
    else
        if ~isPaired
            fprintf('adaptP3X_scld: poles are not conjugate-paired - using standard Newton system\n');
        else
            fprintf(['adaptP3X_scld: %d maxima found, does not match %d poles - using standard ' ...
                'Newton system\n'], nMaxFound, Np);
        end
        [H, w, f] = adaptP3Standard(z, k, p1, Np, wp, deltT, wz, R_MAX);
    end

    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w(:));
    figure;
    plot(f,gdH,'r','LineWidth',1);
    a = 1;
end

function [bestP1, bestCount] = refineExtremaCount(z, k, m, aInit, Np, maxIters, nudgeStep, label, wp)
%   Pairwise-nudge refinement of a starting angle configuration aInit,
%   tracking the best (most group-delay extrema) configuration seen -
%   see adaptP3X_scld's own comments above its call to this function for the
%   full rationale.
    p1 = m.*exp(j*aInit);
    H1 = zpk(z, p1, k);
    wz = fndZeroCrsX_scld(H1, wp);
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
        fprintf(['adaptP3X_scld (%s): short %d extrema (found %d, best %d, need ' ...
            '%d) - separating poles %d and %d (gap %.4g rad), attempt %d\n'], ...
            label, (2*Np-1)-length(wz), length(wz), bestCount, 2*Np-1, kA, kB, ...
            minGap, iter);
        aCur(kA) = aCur(kA) - nudgeStep/2;
        aCur(kB) = aCur(kB) + nudgeStep/2;
        p1 = m.*exp(j*aCur);
        H1 = zpk(z, p1, k);
        wz = fndZeroCrsX_scld(H1, wp);
        if length(wz) > bestCount
            bestCount = length(wz);
            bestP1 = p1;
        end
    end
end

function ripple = candidateRipple(z, k, p1, wp)
%   (max-min)/mean group-delay ripple across ALL found extrema for a
%   candidate starting configuration p1 - used to rank starting
%   candidates that already meet the extrema-count threshold by quality,
%   not just by count (see adaptP3X_scld's own comments above its candidate
%   selection loop). Returns Inf if fewer than 2 extrema are found (not
%   enough to assess ripple), matching dsgnEquiRplGD.m's own convention
%   for this same calculation.
    H1 = zpk(z, p1, k, 1);
    wz = fndZeroCrsX_scld(H1, wp);
    if length(wz) < 2
        ripple = Inf;
        return
    end
    [~, ~, gdH] = AnlzDH(H1, wz(:));
    ripple = (max(gdH) - min(gdH)) / mean(gdH);
end

function isPaired = checkConjugatePairing(p, Np)
%   Check whether p (length Np, in the SAME index order plSens.m assumes
%   for its mirror-row convention: index l paired with index Np-l+1) are
%   exact conjugate pairs within a numerical tolerance - required for
%   adaptP3Reduced's reduced real-parameter Jacobian to be valid.
%   Guaranteed by construction for every current adaptP3X_scld caller
%   (dsgnEquiRplGD.m re-centers to baseband before calling adaptP3X_scld), but
%   checked explicitly here rather than assumed, so a future caller
%   handing genuinely asymmetric poles falls back safely to
%   adaptP3Standard instead of silently producing a wrong result.
    tol = 1e-6 * max(abs(p));
    nPairs = floor(Np/2);
    isPaired = true;
    for l = 1:nPairs
        mirr = Np - l + 1;
        if abs(p(l) - conj(p(mirr))) > tol
            isPaired = false;
            return
        end
    end
    if mod(Np,2) == 1
        mid = ceil(Np/2);
        if abs(imag(p(mid))) > tol
            isPaired = false;
        end
    end
end

function [wzMax, TzMax, wzMin, TzMin] = classifyExtrema(H, wz)
%   Split found group-delay extrema wz into local maxima and minima via
%   AnlzDH's second derivative (d2TdW) sign - negative curvature is a
%   local maximum, positive is a local minimum. AnlzDH already computes
%   this; nothing upstream (fndZeroCrsX_scld, setY2) previously used it -
%   setY2's existing alternating-index convention has no real curvature
%   check at all, so this is a strictly more correct classification, not
%   just new machinery for adaptP3Reduced's sake.
    if isempty(wz)
        wzMax = []; TzMax = []; wzMin = []; TzMin = [];
        return
    end
    [~, ~, gdH, ~, ~, ~, d2TdW] = AnlzDH(H, wz(:));
    isMax = d2TdW < 0;
    wzMax = wz(isMax); TzMax = gdH(isMax);
    wzMin = wz(~isMax); TzMin = gdH(~isMax);
end

function J = reducedSens(p, Np, wzSet)
%   Reduced-parameter sensitivity of group delay at frequencies wzSet
%   with respect to the poles' true independent real parameters, given
%   exact conjugate-pair symmetry (index l paired with Np-l+1, matching
%   plSens.m's own convention - see checkConjugatePairing). Built by
%   linearly combining plSens's raw per-pole real/imag columns: moving
%   the reduced real parameter r_l (shared real part of pair l) shifts
%   BOTH p(l) and p(mirr)'s real parts together, so their real-part
%   sensitivity columns add; moving the reduced imaginary parameter x_l
%   shifts p(l)'s imaginary part by +dx and p(mirr)'s by -dx (since
%   Im(p(mirr)) = -Im(p(l)) exactly), so their imag-part sensitivity
%   columns subtract. This structurally enforces the symmetry that
%   plSens's own single ad hoc constraint row only weakly approximated -
%   no equivalent constraint row is needed here, which is the whole
%   point (see adaptP3X_scld's own comments on why the standard system is
%   near-singular).
    Np = double(Np);
    nPairs = floor(Np/2);
    hasSingle = mod(Np,2) == 1;
    rawSens = plSens(p, wzSet);
    rawSens = rawSens(1:end-1, :); % drop plSens's own ad hoc constraint row - not needed
    J = zeros(size(rawSens,1), 2*nPairs + hasSingle);
    for l = 1:nPairs
        mirr = Np - l + 1;
        J(:, 2*l-1) = rawSens(:,l) + rawSens(:,mirr);
        J(:, 2*l)   = rawSens(:,l+Np) - rawSens(:,mirr+Np);
    end
    if hasSingle
        mid = ceil(Np/2);
        J(:, end) = rawSens(:, mid);
    end
end

function p = applyReducedStep(p, dParams, Np, step)
%   Apply a reduced-parameter Newton step, expanding it back out to the
%   full conjugate-paired complex pole vector (see reducedSens for the
%   parameterization).
    nPairs = floor(Np/2);
    hasSingle = mod(Np,2) == 1;
    for l = 1:nPairs
        mirr = Np - l + 1;
        dpl = dParams(2*l-1) + 1i*dParams(2*l);
        p(l) = p(l) - step*dpl;
        p(mirr) = p(mirr) - step*conj(dpl);
    end
    if hasSingle
        mid = ceil(Np/2);
        p(mid) = p(mid) - step*dParams(end);
    end
end

function [H, w, f] = adaptP3Reduced(z, k, p1, Np, wp, deltT, R_MAX)
%   Reduced conjugate-pair Newton loop - see adaptP3X_scld's own comments
%   above its call to this function for the full rationale and
%   validation numbers.
    deltW = 1e-5*2*pi;
    p = p1;
    N = 200;
    uP = logspace(-2,-1.5,N); % same damping schedule as adaptP3Standard

    % Unlike adaptP3Standard's per-pole collision freeze, this reduced
    % system's square shape depends on the FULL Np-maxima/matching
    % structure holding every iteration - there's no way to locally
    % patch a single colliding pair without breaking the reduced
    % parameterization's premise. If the maxima/minima structure itself
    % changes, retry a few iterations (a single bad step can transiently
    % disturb classification) before giving up with a clear error,
    % mirroring adaptP3Standard's own collision-halt convention.
    STRUCTURE_MAX_BAD_ITERS = 5;
    structureBadIters = 0;

    for i = 1:N
        H = zpk(z, p, k, 1);
        wz = fndZeroCrsX_scld(H, wp);
        [wzMax, TzMax, wzMin, TzMin] = classifyExtrema(H, wz);

        if length(wzMax) ~= Np || isempty(wzMin)
            structureBadIters = structureBadIters + 1;
            fprintf(['adaptP3X_scld (reduced): maxima/minima structure changed (%d maxima, ' ...
                'need %d) - attempt %d of %d\n'], length(wzMax), Np, structureBadIters, ...
                STRUCTURE_MAX_BAD_ITERS);
            if structureBadIters > STRUCTURE_MAX_BAD_ITERS
                error('adaptP3X_scld:reducedStructureLost', ...
                    ['adaptP3X_scld (reduced): maxima/minima structure changed (found %d maxima, ' ...
                    'need %d) and did not recover after %d iterations - group-delay ' ...
                    'adaptation halted'], length(wzMax), Np, STRUCTURE_MAX_BAD_ITERS);
            end
            continue
        end
        structureBadIters = 0;

        meanMinNow = mean(TzMin);
        Jmax = reducedSens(p, Np, wzMax);
        Jmin = reducedSens(p, Np, wzMin);
        Jbar_min = mean(Jmin, 1);
        A = Jmax - ones(Np,1)*Jbar_min;
        Yres = TzMax(:) - meanMinNow - deltT;

        if any(~isfinite(A(:)))
            continue
        end
        % pinv rather than a strict A\Yres solve: A is EXACTLY (not just
        % numerically) rank-deficient whenever two maxima sit at bit-
        % identical mirror frequencies +w/-w, which happens whenever a
        % starting candidate's poles are bit-exact conjugate pairs (e.g.
        % the even-spacing candidate's linspace-constructed angles,
        % confirmed on dig_linPh_1_6_0.m: rcond(A)=4e-18 on iteration 1) -
        % T(w)=T(-w) identically for any conjugate-paired pole set, so
        % their reduced-parameter sensitivity rows are mathematically
        % guaranteed identical too, not just numerically close. This
        % isn't a rare fluke; it's the generic case for "nicely behaved"
        % symmetric starting configurations. pinv finds the minimum-norm
        % least-squares solution instead of refusing to solve - the same
        % established pattern examples/eqlzrD_peakNewtonStep.m already
        % uses for its own non-square/rank-deficient systems, rather than
        % new machinery invented for this file.
        dParams = pinv(A) * Yres;
        if any(~isfinite(dParams)) || any(abs(dParams) > 50)
            continue
        end

        p = applyReducedStep(p, dParams, Np, uP(i));
        tooBig = abs(p) > R_MAX;
        p(tooBig) = R_MAX * p(tooBig)./abs(p(tooBig));
    end

    w1 = angle(p);
    wrng = 1.2*[min(w1) max(w1)];
    w = wrng(1):deltW:wrng(2);
    f = w./(2*pi);
end

function [H, w, f] = adaptP3Standard(z, k, p1, Np, wp, deltT, wz, R_MAX)
%   Standard (plSens/setY2) Newton loop - the original algorithm, used
%   whenever adaptP3Reduced's preconditions don't hold. See adaptP3X_scld's
%   own comments above its call to this function for why it's kept as
%   the fallback rather than replaced outright.
    deltW = 1e-5*2*pi;
    H1 = zpk(z, p1, k);
    w1 = angle(p1);
    wrng = 1.2*[w1(1) w1(end)];
    w = wrng(1):deltW:wrng(2);
    Tz = p2T(H1, wz);

    p = p1;
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
    % happens, fndZeroCrsX_scld legitimately finds fewer genuine group-delay
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
        wz = fndZeroCrsX_scld(H, wp);
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
            for mm = 1:(length(sortedFree)-1)
                kA = sortedFree(mm);
                kB = sortedFree(mm+1);
                if abs(p(kB) - p(kA)) < COLLISION_TOL
                    fprintf(['adaptP3X_scld: poles %d and %d drifted to nearly the ' ...
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
            % fndZeroCrsX_scld already assume elsewhere in this file) and
            % freeze one of them.
            [~, sortIdx] = sort(angle(p(freeIdx)));
            sortedFree = freeIdx(sortIdx);
            for mm = 1:(length(sortedFree)-1)
                kA = sortedFree(mm);
                kB = sortedFree(mm+1);
                if abs(p(kB) - p(kA)) < COLLISION_TOL
                    fprintf(['adaptP3X_scld: poles %d and %d converged to nearly the ' ...
                        'same position (%.4g%+.4gi, %.4g%+.4gi) - freezing ' ...
                        'pole %d\n'], kA, kB, real(p(kA)), imag(p(kA)), ...
                        real(p(kB)), imag(p(kB)), kB);
                    frozen(kB) = true;
                    break
                end
            end
            collisionIters = collisionIters + 1;
            if collisionIters > COLLISION_MAX_ITERS
                error('adaptP3X_scld:tooFewExtrema', ...
                    ['adaptP3X_scld: only found %d group-delay extrema for %d free ' ...
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
        tooBig = abs(p) > R_MAX;
        p(tooBig) = R_MAX * p(tooBig)./abs(p(tooBig));
    end
end
