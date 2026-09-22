% Driver for eqlzrD_peakNewtonStep.m. Starts from the 3-cluster
% (15%/54%/90%, r=0.925, 5 stages each) configuration explored by hand in
% dsgnEqlzrD_manual.m, then runs TWO phases:
%
%   Phase 1 (angle-only): repeatedly calls eqlzrD_peakNewtonStep with
%   freeR=false to adjust the three cluster angles (r held fixed) to
%   drive ALL of the current group delay's local extrema's gain-weighted
%   deviation from the anchor toward equality (not just the original two
%   edge peaks -- see eqlzrD_peakNewtonStep.m's own header for why that
%   was wrong). Runs up to PHASE1_MAX_ITERS (50) steps, or stops early
%   once the weighted-deviation spread changes by less than SPREAD_TOL
%   (1e-4) between consecutive steps -- angle-only convergence is clean
%   and monotonic, so a simple small-delta check is appropriate here.
%
%   Phase 2 (angle+radius, freeR=true): from the phase-1-converged point,
%   also lets the three cluster radii move, jointly with the angles, in
%   the same least-squares Newton step. Tried per direct instruction
%   after phase-1-only convergence left visibly unequal peaks; a NAIVE
%   standalone radius tweak (just shrinking the center cluster, even with
%   angles fully re-optimized around the new radius) made things WORSE,
%   not better -- see eqlzrD_peakNewtonStep.m's own header for the
%   verified numbers. Solving jointly genuinely helps (confirmed: nominal
%   p2p ~22.9 -> ~16.7, roughly 27% better, within a few steps) but does
%   NOT converge cleanly to a fixed point the way phase 1 does: spread
%   bottoms out early, then slowly drifts back up over further
%   iterations while p2p on the wider expanded band keeps improving (a
%   real nominal-vs-expanded trade-off, not simple convergence). So phase
%   2 uses a "best spread seen so far, stop after PATIENCE consecutive
%   non-improving steps" rule instead of phase 1's small-delta check, and
%   reverts to the BEST configuration found, not whatever the last step
%   happened to land on.
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

% Starting configuration: three free interior clusters (all frequencies
% adjustable; radii start shared and fixed for phase 1).
clusterTheta = 2*pi*[wp_(1)+0.15*diff(wp_), wp_(1)+0.54*diff(wp_), wp_(1)+0.90*diff(wp_)];
clusterR = [0.925, 0.925, 0.925];
clusterCount = [5, 5, 5];

plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);
fprintf('\nInitial setup plotted. anchor=%.4f\n', anchor);

%% Phase 1: angle-only, small-delta convergence
PHASE1_MAX_ITERS = 50;
SPREAD_TOL = 1e-4;

fprintf('\n--- Phase 1: angle-only ---\n');
spreadPrev = Inf;
converged = false;
for iter = 1:PHASE1_MAX_ITERS
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_);
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

fprintf('\n--- Phase 2: joint angle+radius ---\n');
bestSpread = info.spreadBefore;
bestTheta = clusterTheta;
bestR = clusterR;
bestInfo = info;
noImprove = 0;
for iter = 1:PHASE2_MAX_ITERS
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_, [], [], true);
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
