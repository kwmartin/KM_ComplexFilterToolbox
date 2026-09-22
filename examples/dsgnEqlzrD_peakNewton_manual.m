% Driver for eqlzrD_peakNewtonStep.m. Starts from a 5-cluster (10/30/50/
% 70/90% of the passband, r=0.925, 5 stages each) configuration -- more
% clusters than the original 3-cluster hand-tuned start (15%/54%/90%),
% per direct instruction: more clusters means more free angle DOF
% relative to the ~9 tracked extrema, the most direct lever on the
% DOF-vs-extrema-count mismatch that keeps angle-only convergence from
% reaching a true equal-ripple result. Then runs TWO phases:
%
%   Phase 1 (angle-only): repeatedly calls eqlzrD_peakNewtonStep with
%   freeR=false to adjust the cluster angles (r held fixed) to drive ALL
%   of the current group delay's local extrema's gain-weighted deviation
%   from the anchor toward equality (not just the original two edge
%   peaks -- see eqlzrD_peakNewtonStep.m's own header for why that was
%   wrong). Runs up to PHASE1_MAX_ITERS (100) steps, or stops early once
%   the weighted-deviation spread changes by less than SPREAD_TOL (1e-4)
%   between consecutive steps.
%
%   STEP1_SIZE is 0.2, not the function's own default damping of 0.5:
%   at 5 clusters, the default step size was tested and found unstable --
%   the tracked extremum count itself oscillated wildly (3 to 11) and
%   spread swung between 13 and 300 for the first ~35 of 50 steps before
%   finally settling (it did eventually reach a reasonable point, but the
%   path there was nothing like the clean monotonic descent 3 clusters
%   gave). More free parameters against the same roughly-9 tracked
%   extrema makes the pinv least-squares step more aggressive per unit
%   computed magnitude; more damping compensates. At STEP1_SIZE=0.2,
%   descent is smooth and monotonic throughout, converging cleanly by
%   ~step 84.
%
%   Phase 2 (angle+radius, freeR=true): from the phase-1-converged point,
%   also lets the cluster radii move, jointly with the angles, in the
%   same least-squares Newton step. Tried per direct instruction after
%   phase-1-only convergence left visibly unequal peaks; a NAIVE
%   standalone radius tweak (just shrinking one cluster, even with angles
%   fully re-optimized around the new radius) made things WORSE, not
%   better -- see eqlzrD_peakNewtonStep.m's own header for the verified
%   3-cluster numbers. Solving jointly genuinely helps. It does NOT
%   converge cleanly to a fixed point: spread bottoms out early then
%   slowly drifts back up over further iterations while p2p on the wider
%   expanded band keeps improving (a real nominal-vs-expanded trade-off,
%   not simple convergence) -- so phase 2 tracks the BEST spread seen so
%   far and stops after PATIENCE consecutive non-improving steps,
%   reverting to that best configuration rather than whatever the last
%   step landed on.
%
%   STEP2_SIZE is 0.1 (function default 0.5 is even MORE unstable here
%   than in phase 1: tested at 5 clusters and the default step size blew
%   up outright by step 3 -- radii pinned to their [0.3, 0.995] clamp
%   bounds and spread exploding past 1900, a p2p_nominal in the
%   thousands. At STEP2_SIZE=0.1, phase 2 is smooth and well-behaved, no
%   clamping, finding its best point (p2p_nominal ~13.8-13.9, better than
%   3 clusters' ~16.7, at some further cost to the expanded-band metric)
%   within about 13 steps).
%
% Plots the final (best) result and drops into a keyboard breakpoint.
% From there, take additional manual steps (the fprintf message at the
% breakpoint shows the exact call, freeR included), inspect "info",
% "clusterTheta", "clusterR", etc., or "dbcont"/"dbquit" to finish.

addpath('../lib');
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

p = [-0.35 -0.25 -0.1 -0.08 0.25 0.35];
ni = 1;
wp = []; ws = [];
wp(1) = -0.025; wp(2) = 0.025;
ws = [-0.49 -0.049 0.049 0.49];
as = [70 50 50 70];
Ap = 0.05;
px = [];
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);

cscdFltr1 = dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
H = cscdFltr1.getSystem();

[~, stats] = estAllPassOrder(H, wp_);
f = stats.f(:);
w = 2*pi*f;
gdH0 = stats.gdH(:);

% Fixed anchor: mean of H's own two edge peaks (unweighted, per this
% session's discussion). Never recomputed after this point.
pkMask0 = islocalmax(gdH0, 'MinProminence', 5);
anchor = mean(gdH0(pkMask0));

% Starting configuration: five free interior clusters, evenly spaced
% across the passband (all frequencies adjustable; radii start shared
% and fixed for phase 1).
fracs = linspace(0.10, 0.90, 5);
clusterTheta = 2*pi*(wp_(1) + fracs*diff(wp_));
clusterR = 0.925*ones(1,5);
clusterCount = 5*ones(1,5);

plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);
fprintf('\nInitial setup plotted. anchor=%.4f\n', anchor);

%% Phase 1: angle-only, small-delta convergence
PHASE1_MAX_ITERS = 100;
SPREAD_TOL = 1e-4;
STEP1_SIZE = 0.2;

fprintf('\n--- Phase 1: angle-only ---\n');
spreadPrev = Inf;
converged = false;
for iter = 1:PHASE1_MAX_ITERS
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_, STEP1_SIZE);
    fprintf('step %2d: nExtrema=%2d  spread=%.6f\n', iter, info.nExtrema, info.spreadBefore);
    if abs(info.spreadBefore - spreadPrev) < SPREAD_TOL
        converged = true;
        fprintf('Phase 1 converged after %d step(s) (spread change < %.g).\n', iter, SPREAD_TOL);
        break
    end
    spreadPrev = info.spreadBefore;
end
if ~converged
    fprintf('Phase 1 stopped at PHASE1_MAX_ITERS=%d without reaching the %.g tolerance.\n', ...
        PHASE1_MAX_ITERS, SPREAD_TOL);
end

%% Phase 2: joint angle+radius, best-so-far with patience
PHASE2_MAX_ITERS = 50;
PATIENCE = 5;
STEP2_SIZE = 0.1;

fprintf('\n--- Phase 2: joint angle+radius ---\n');
bestSpread = info.spreadBefore;
bestTheta = clusterTheta;
bestR = clusterR;
bestInfo = info;
noImprove = 0;
for iter = 1:PHASE2_MAX_ITERS
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_, STEP2_SIZE, [], true);
    fprintf('step %2d: nExtrema=%2d  spread=%.6f  r=%s  rClamped=%d\n', ...
        iter, info.nExtrema, info.spreadBefore, mat2str(clusterR,4), info.rClamped);
    if info.spreadBefore < bestSpread
        bestSpread = info.spreadBefore;
        bestTheta = clusterTheta;
        bestR = clusterR;
        bestInfo = info;
        noImprove = 0;
    else
        noImprove = noImprove + 1;
        if noImprove >= PATIENCE
            fprintf('Phase 2 stopped after %d step(s) without improvement (best spread=%.6f at an earlier step).\n', ...
                PATIENCE, bestSpread);
            break
        end
    end
end
clusterTheta = bestTheta;
clusterR = bestR;
info = bestInfo;

plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);
fprintf('\nUsing BEST phase-2 configuration found (spread=%.6f), not necessarily the last step.\n', bestSpread);
disp(info);

fprintf('\nDone. Final: nExtrema=%d, weightedDev spread=%.6f, r=%s\n', ...
    info.nExtrema, bestSpread, mat2str(clusterR,4));
fprintf('To take another step by hand, run at this prompt:\n');
fprintf('  [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_, [], [], true);\n');
fprintf('  plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);\n');
fprintf('(drop the trailing "true" for an angle-only step.) Repeat as many times as you like.\n');
fprintf('Type dbcont to finish, dbquit to abort.\n');
keyboard

a = 1; % execution resumes here after "dbcont"

function plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor)
  wiVec = repelem(clusterR, clusterCount) .* exp(1j*repelem(clusterTheta, clusterCount));
  eq = eqlzrDClass(wiVec(:), 1);
  Heq = eq.applyTo(H);
  [~, stats] = estAllPassOrder(H, wp_);
  f = stats.f(:);
  w = 2*pi*f;
  [~, ~, gdH0] = AnlzDH(H, w);
  [~, ~, gdH1] = AnlzDH(Heq, w);
  idx_nom = f >= wp_(1) & f <= wp_(2);

  fig = figure('Position', [100 100 900 500]);
  plot(f, gdH0, 'b', 'LineWidth', 1.2); hold on;
  plot(f, gdH1, 'r', 'LineWidth', 1.2);
  yline(anchor, 'k--');
  xline(wp_(1), ':k'); xline(wp_(2), ':k');
  for th = clusterTheta
    xline(th/(2*pi), 'g:');
  end
  legend('unequalized gdH', 'equalized gdH', 'anchor', 'nominal wp edges', 'cluster angles', 'Location', 'best');
  xlabel('f (cycles)'); ylabel('group delay (samples)');
  title(sprintf('%d clusters, r=[%s]: p2p nominal=%.2f expanded=%.2f', ...
      length(clusterTheta), mat2str(clusterR,3), ...
      max(gdH1(idx_nom))-min(gdH1(idx_nom)), max(gdH1)-min(gdH1)));
  grid on;
end
