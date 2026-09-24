function Hz = place_polesdLP3_scld(H,wp)
%   [_scld copy of place_polesdLP3.m - converts back to z with y2zSbTrnsf1_scld; see ScldGD.md section 10]
%   Hy = place_polesdLP(e,p,ni,w,e_,type,px)
%   This is a program for placing loss poles to equalize stop-band
%   minima. The specifications need not be constant or symmetric
%   This version can handle finite unmoveable poles
%   specified in px.
%
%   e: the zeros which are not moved (also equal to the natural modes)
%   p: Initial guess at finite loss poles
%   px: fixed poles
%   ni: number of poles at infinity
%
%   e_ = 0.25; % passband magnitude squared ripple = 1 + e_^2
%
%   type is 'monotonic' for a maximally flat pass-band and 'elliptic' for
%   an equiripple pass-band
%
%   For detailed explanation see:
%   K. Martin, “Approximation of complex iir bandpass filters without arith-
%   metic symmetry,” IEEE Trans. Circuits and Systems I, vol. 52, pp. 794–
%   803, April 2005.
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

%Transform used for discrete time to continous-time with stop-band at jw for 0 < w < Inf
z2y = @(z,wi)(j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
w2x = @(w, wi) -((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1)));
y2z = @(y,wi)((2*j - wi(2) - y.*(2 + j*wi(1)))./(2*j + wi(2) - y.*(2 - j*wi(1))));
x2w = @(x,wi)(2.*atan((wi(2)*ones(size(x)) - wi(1).*x)./(2*ones(size(x)) - 2.*x)));

% We first transform to y ensuring we include the stop-band but not the
% pass-band
dWp = 0.2*(wp(2) - wp(1))/2;
fsb1 = [wp(1)- dWp, wp(2) + dWp];
Hy1 =  z2ySbTrnsf1(H,fsb1);
Hy1 = 1/Hy1;
% Now we find the edge frequencies have the same loss as the average of the
% stop-band loss minima
wt1 = 2*pi*fsb1;
wsy = [0, 0.9999, 1.00001, 1e6];
ns = 4;
asy = 20*ones(size(wsy));
zmin = findLossMinima(Hy1,wsy,asy);
lossMin = db(rsps(Hy1,j*zmin));
avgLsMin = mean(lossMin);
py = sortImag(Hy1.p{1});
wy1 = imag([0.9*py(1) 1.1*py(end)]);
wy2 = findLossEdges(Hy1,avgLsMin,wy1);
% Now transform these back to z and use them as the basis
% for transforming back to y. This new transform will have band edge losses
% equal to the average of the loss minima
fsb2 = sort(x2w(wy2, 2*tan(wt1/2)))/(2*pi);
Hy2 =  z2ySbTrnsf1(H,fsb2);
Hy2 = 1/Hy2;

a=1;

[ey, py, ky] = sortZPK(Hy2);
py = py.'; % convert to column
py = imag(py) % convert to real for adaptation; we'll convert back later
Hy = Hy2;
np = length(py);

% Ensure the STARTING configuration already has enough independent
% stop-band loss minima (np+1, the threshold the main loop's collision
% monitor below uses) before the Newton loop even begins - mirrors the
% identical fix added to adaptP3.m's group-delay stage (see its comments
% for the full rationale). Confirmed needed here too:
% dig_linPh_1_6_0.m reaches this stage with its group-delay side fully
% resolved (by adaptP3.m's own version of this fix) but starts short by
% 1 minimum right here.
%
% Two starting heuristics are tried, each independently refined to
% convergence (or INIT_MAX_ITERS attempts) by pairwise-nudging the most
% at-risk adjacent pair apart (see refineMinimaCount below): (1) the
% natural sortZPK-derived py ordering, and (2) a more global even
% redistribution of all np positions across the same [min(py),max(py)]
% span. Keep whichever FULLY-REFINED result ends up better - picking
% only the better STARTING point and refining once regressed on
% adaptP3.m's identical problem (see its comments for the confirmed
% example), so both heuristics are always run to full completion here
% too rather than just picking the better start.
INIT_MAX_ITERS = 60;
NUDGE_TOL = 1e-3; % matches COLLISION_TOL below

pyEven = linspace(min(py), max(py), np).';
[py_nat, count_nat] = refineMinimaCount(ey, ky, py, wsy, asy, ns, np, INIT_MAX_ITERS, NUDGE_TOL, 'natural');
[py_even, count_even] = refineMinimaCount(ey, ky, pyEven, wsy, asy, ns, np, INIT_MAX_ITERS, NUDGE_TOL, 'even-spacing');
if count_even > count_nat
    py = py_even;
    bestCount = count_even;
    chosenLabel = 'even-spacing';
else
    py = py_nat;
    bestCount = count_nat;
    chosenLabel = 'natural';
end
fprintf(['place_polesdLP3: starting heuristics refined - natural reached ' ...
    '%d, even-spacing reached %d, using %s (need %d)\n'], count_nat, ...
    count_even, chosenLabel, np+1);
Hy = zpk(ey, j*py, ky);
if bestCount < np + 1
    fprintf(['place_polesdLP3: could not reach %d starting minima after ' ...
        'both refinements (best %d) - proceeding anyway.\n'], np+1, bestCount);
end

X = [py(:); 0];

% Some poles can converge to (nearly) the same position - the notch between
% two adjacent poles that are essentially coincident vanishes, so
% findLossMinima legitimately finds one fewer independent stop-band minimum
% than there are movable poles. frozen tracks poles we've stopped updating
% in response (so the sensitivity/Newton system shrinks to match), and
% collisionIters counts iterations since the last freeze where the system is
% still short a minimum - if that doesn't resolve within COLLISION_MAX_ITERS,
% we give up with a clear error instead of crashing on a bare dimension
% mismatch.
COLLISION_TOL = 1e-3;
COLLISION_MAX_ITERS = 5;
frozen = false(1,np);
collisionIters = 0;

% Adapt the pole positions to equalize the stop-band loss minima
% Note we have made the loss pole positions real
for i = 1:2000 % repeat enough times to guarantee success
    zmin = findLossMinima(Hy,wsy,asy); % find the minima of the stop-band loss
    % Augument with stop-band edge frequencies.
    zmin = [wsy(1); zmin; wsy(ns)];
    % Most functions can't handle Inf which corresponds to wp(2)
    zmin(zmin == Inf) = 1e6; % The might be too small for very high order filters

    [mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,asy,zmin);
    [zmnSrt indxs] = sort(mrgn);
    freeIdx = find(~frozen);
    npFree = length(freeIdx);
    if length(indxs) > npFree + 1
        zmin = zmin(indxs(1:npFree+1));
        mrgn = mrgn(indxs(1:npFree+1));
    end
    % system is over-determined. Different approaches could be considered
    % here.
    nz = length(zmin);

    % Proactively freeze any free pole pair that has already drifted
    % within COLLISION_TOL, even if nz hasn't dropped below threshold
    % yet. Waiting for that symptom was found to be too late: a starting
    % configuration that comfortably meets the required minima count can
    % still drift back into collision over the course of this loop and
    % fail regardless (confirmed on dig_linPh_1_6_0.m: starts at exactly
    % 8 minima for 7 free poles, meeting the threshold, but the loop
    % still degrades it to 5 and halts -- checking proximity directly,
    % every iteration, catches drift before it becomes a shortfall
    % instead of after).
    if npFree > 1
        for m = 1:(length(freeIdx)-1)
            k = freeIdx(m);
            kNext = freeIdx(m+1);
            if (abs(py(kNext) - py(k)) < COLLISION_TOL)
                fprintf(['place_polesdLP3: poles %d and %d drifted to ' ...
                    'nearly the same position (%.6g, %.6g) - freezing ' ...
                    'pole %d\n'], k, kNext, py(k), py(kNext), kNext);
                frozen(kNext) = true;
                freeIdx = find(~frozen);
                npFree = length(freeIdx);
                % zmin/mrgn were already truncated to the OLD npFree+1
                % (in sorted-by-severity order via indxs above), so a
                % further prefix truncation to the NEW, smaller npFree+1
                % is safe and keeps the worst-margin points -- needed so
                % Sfree(:,freeIdx) below stays row-count-consistent with
                % s2 (npFree+1 rows) after npFree just shrank.
                if length(zmin) > npFree + 1
                    zmin = zmin(1:npFree+1);
                    mrgn = mrgn(1:npFree+1);
                end
                nz = length(zmin);
                break
            end
        end
    end

    if nz < npFree + 1
        % Too few independent minima for the current free-pole count. Look
        % for a newly-collided pair among the still-free poles and freeze
        % one of them (the linear system shrinks to match next iteration).
        for m = 1:(length(freeIdx)-1)
            k = freeIdx(m);
            kNext = freeIdx(m+1);
            if (abs(py(kNext) - py(k)) < COLLISION_TOL)
                fprintf(['place_polesdLP3: poles %d and %d converged to ' ...
                    'nearly the same position (%.6g, %.6g) - freezing ' ...
                    'pole %d\n'], k, kNext, py(k), py(kNext), kNext);
                frozen(kNext) = true;
                break
            end
        end
        collisionIters = collisionIters + 1;
        if collisionIters > COLLISION_MAX_ITERS
            error('place_polesdLP3:tooFewMinima', ...
                ['place_polesdLP3: only found %d independent stop-band ' ...
                'loss minima for %d free pole(s) after freezing colliding ' ...
                'poles for %d iterations - pole placement halted'], ...
                nz, npFree, COLLISION_MAX_ITERS);
        end
        % Whether or not a new collision was found to freeze this pass,
        % retry next iteration rather than building an undersized system.
        continue
    end
    collisionIters = 0;

    Y = -mrgn;
    s2 = -1*ones(npFree+1,1);

    Sfree = dHy_dp2(Hy,zmin);
    S = [Sfree(:,freeIdx) s2];
    Pmin = 1e-6.*diag(ones(1,npFree+1));
    Xfree = (S + Pmin)\(Y); % Calculate the changes in the free pole frequencies

    if any(~isfinite(Xfree)) || any(abs(Xfree) > 50)
        % Same two-part fix, and same underlying cause, as
        % place_polesdLP5.m's identical check: a pole landing very close
        % to (but not exactly at) a zmin probe point makes dHy_dp2's
        % 1/(w-pole) term huge without being exactly singular, producing
        % a finite-but-enormous step that corrupts py just as badly as
        % an outright non-finite one (confirmed here: the isfinite check
        % alone did not stop dig_linPh_1_6_0.m's later zpk() NaN/Inf
        % crash - the finite-but-huge regime still reached it). Reject
        % the step and retry next iteration instead.
        continue
    end

    delta = zeros(1,np);
    delta(freeIdx) = Xfree(1:npFree).';
    % Damping factor reduced from the original 1.0 (full Newton step):
    % an undamped step was found to overshoot and drive poles back into
    % collision even from a starting configuration that already met the
    % required minima count (confirmed on dig_linPh_1_6_0.m -- starts at
    % exactly 8 minima for 7 free poles, meeting the threshold, but an
    % undamped step still degrades it to 5 and halts, even with the
    % proactive proximity check above catching the same collisions no
    % earlier than the reactive one used to). A smaller step trades
    % iteration count for stability.
    STEP_DAMPING = 0.3;
    py = py + STEP_DAMPING.*delta; % Calculate the new pole positions
    % p = sort(p)

    % Check limits and make sure poles don't pass each other
    for k=1:np
        if (k < np) && (py(k) >= py(k+1))
            py(k) = 0.999*py(k+1);
        end
        if (py(k) <= wsy(1))
            % wsy(1) is always 0 here, so the old "1.001*wsy(1)" nudge was a
            % no-op (1.001*0 == 0) - a clamped pole landed exactly on the
            % wsy(1)=0 probe point zmin always includes, making dHy_dp2's
            % 1/(w - pole) divide by exact zero (Inf), which then makes the
            % Newton-step sensitivity matrix singular. Use an absolute
            % epsilon instead, matching this file's own 1e-4-scale
            % boundary-avoidance convention (wsy = [0, 0.9999, 1.00001, 1e6]).
            py(k) = wsy(1) + 1e-4;
        end
        if (py(k) >= wsy(ns))
            py(k) = 0.999*wsy(ns);
        end
    end
    if max(abs(delta)) < 1e-10
        fprintf('Minima Iteration Terminated in %d iters, error: %d\n', ...
            i, max(abs(delta)));
        break
    end

    % max(abs(delta))
    Hy = zpk(ey,j*sort(py),ky);
end

zmin = findLossMinima(Hy,wsy,asy); % find the minima of the stop-band loss
zmin = [wsy(1); zmin; wsy(ns)];
zmin(zmin == Inf) = 1e6; % The might be too small for very high order filters
[mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,asy,zmin);
% display('Minima Frequencies');
% zmin
% display('Stopband Margins');
% 20*mrgn./log(10);
Hy = 1/Hy; % return in forward gain form, not in loss form
Hz = y2zSbTrnsf1_scld(Hy,fsb2);
Hz.k = Hz.k/(abs(rspsd(Hz,j*(wp(2) + wp(1))*pi)));
a=1; % a place to stop for debugging
end

function [bestPy, bestCount] = refineMinimaCount(ey, ky, pyInit, wsy, asy, ns, np, maxIters, nudgeTol, label)
%   Pairwise-nudge refinement of a starting loss-pole configuration
%   pyInit, tracking the best (most stop-band minima) configuration seen
%   - see place_polesdLP3's own comments above its call to this function
%   for the full rationale.
    py = sort(pyInit);
    Hy = zpk(ey, j*py, ky);
    zminI = findLossMinima(Hy,wsy,asy);
    zminI = [wsy(1); zminI; wsy(ns)];
    zminI(zminI == Inf) = 1e6;
    mrgnI = getMarginLP(Hy,wsy,asy,zminI);
    [~, indxsI] = sort(mrgnI);
    if length(indxsI) > np + 1
        zminI = zminI(indxsI(1:np+1));
    end
    bestCount = length(zminI);
    bestPy = py;
    iter = 0;
    while bestCount < np + 1 && iter < maxIters
        iter = iter + 1;
        [pySorted, srt] = sort(py);
        gaps = diff(pySorted);
        [minGap, worstIdx] = min(gaps);
        kA = srt(worstIdx);
        kB = srt(worstIdx+1);
        nudgeAmt = max(0.02*max(abs(py(kA)), abs(py(kB))), 5*nudgeTol);
        fprintf(['place_polesdLP3 (%s): short %d minima (found %d, best %d, ' ...
            'need %d) - separating poles %d and %d (gap %.4g), attempt %d\n'], ...
            label, (np+1)-length(zminI), length(zminI), bestCount, np+1, kA, ...
            kB, minGap, iter);
        py(kA) = py(kA) - nudgeAmt/2;
        py(kB) = py(kB) + nudgeAmt/2;
        if py(kA) <= wsy(1)
            py(kA) = wsy(1) + 1e-4;
        end
        if py(kB) >= wsy(ns)
            py(kB) = 0.999*wsy(ns);
        end
        py = sort(py); % order is arbitrary for a zpk pole set - safe to
                        % relabel here
        Hy = zpk(ey, j*py, ky);

        zminI = findLossMinima(Hy,wsy,asy);
        zminI = [wsy(1); zminI; wsy(ns)];
        zminI(zminI == Inf) = 1e6;
        mrgnI = getMarginLP(Hy,wsy,asy,zminI);
        [~, indxsI] = sort(mrgnI);
        if length(indxsI) > np + 1
            zminI = zminI(indxsI(1:np+1));
        end
        if length(zminI) > bestCount
            bestCount = length(zminI);
            bestPy = py;
        end
    end
end
