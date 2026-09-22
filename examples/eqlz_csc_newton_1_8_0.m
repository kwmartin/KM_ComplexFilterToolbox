% Driver for eqlzrD_peakNewtonStep.m, rooted at eqlz_csc_1_8_0.m's
% manually-tuned starting point (5 clusters at 12/30/50/70/88% of the
% passband, r=0.82, 5 stages each -- the config found by hand to actually
% reduce nominal-band p2p group delay: 35.90 -> 28.33, ~21% better, versus
% every r=0.925 config tried earlier making it 3-3.5x WORSE). This driver
% asks whether the Newton peak-equalization iteration (see
% eqlzrD_peakNewtonStep.m's own header for the method) can improve on that
% by hand-picked starting point further.
%
% Step sizes are SMALL here (0.1 phase 1, 0.05 phase 2), smaller even than
% dsgnEqlzrD_peakNewton_manual.m's already-damped 0.2/0.1 (which itself
% found the function's own default of 0.5 unstable at 5 clusters -- angle
% oscillation, spread swinging 13-300 for ~35 steps before settling). This
% starting point differs from that file's in both r (0.82 vs 0.925 -- a
% shallower, more broadband correction, since the passband here is ~9x
% wider) and in already being close to a reasonable local shape (found by
% hand, not a naive guess), so an even gentler step size is used to avoid
% kicking a plausibly-good starting point into the same oscillatory
% behavior, and to see clearly whether the iteration finds an improving
% direction at all before committing to larger, more aggressive steps.
%
% Runs the same two phases as dsgnEqlzrD_peakNewton_manual.m:
%   Phase 1 (angle-only, freeR=false): adjust cluster angles only, r held
%   fixed at 0.82, until the weighted-deviation spread stops changing
%   (SPREAD_TOL) or PHASE1_MAX_ITERS is reached.
%   Phase 2 (joint angle+radius, freeR=true): from the phase-1 result,
%   also let cluster radii move. Tracks the BEST spread seen so far
%   (PATIENCE consecutive non-improving steps stops it) rather than a
%   fixed iteration count or small-delta convergence, since phase 2 is
%   documented (see eqlzrD_peakNewtonStep.m) to bottom out early then
%   drift back up rather than converge to a fixed point.
%
% Prints nominal- and expanded-band p2p group delay (before/after) at the
% start and end so the improvement (if any) over the eqlz_csc_1_8_0.m
% starting point is visible directly in the console output, not just in
% the figure titles.

addpath('../lib');
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

% Same design specification as csc_fltr_1_8_0.m / eqlz_csc_1_8_0.m: 8
% movable poles, 1 pole at infinity, 0 fixed poles, wp = 0.025 to 0.475,
% 0.05dB elliptic passband, positive-pass over almost all positive
% frequencies.
p = [-0.45 -0.40 -0.35 -0.30 0.3 0.35 0.4 0.45];
ni = 1;
wp = []; ws = [];
wp(1) = -0.225; wp(2) = 0.225;
ws = [-0.49 -0.25 0.25 0.49];
as = [50 50 50 50];
Ap = 0.05;
px = [];
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.25);

cscdFltr1 = dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
H = cscdFltr1.getSystem();

[~, stats] = estAllPassOrder(H, wp_);
f = stats.f(:);
w = 2*pi*f;
gdH0 = stats.gdH(:);

% Fixed anchor: mean of H's own two edge peaks (unweighted, same
% convention as dsgnEqlzrD_peakNewton_manual.m). Never recomputed after
% this point. For this filter the two peaks sit right at the passband
% edges (f~0.022 and f~0.478, gd~51.66 each, essentially symmetric).
pkMask0 = islocalmax(gdH0, 'MinProminence', 5);
anchor = mean(gdH0(pkMask0));

% EXPERIMENT (expected to probably revert): 7 clusters instead of 5,
% evenly spaced 10%-90% across the passband, all at r=0.78 (lower than the
% 5-cluster r=0.82 starting point, more stages to cover more DOF). Not
% expected to converge cleanly -- if phase 2 (joint angle+radius) doesn't
% converge, the plan is to retry with phase 2 disabled (angle-only
% throughout, r fixed at 0.78).
fracs = linspace(0.10, 0.90, 7);
clusterTheta = 2*pi*(wp_(1) + fracs*diff(wp_));
clusterR = 0.78*ones(1,7);
clusterCount = 5*ones(1,7);

fprintf('Starting point (from eqlz_csc_1_8_0.m): anchor=%.4f\n', anchor);
plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor, 'Starting point', 'start');

%% Phase 1: angle-only, small-delta convergence
PHASE1_MAX_ITERS = 100;
SPREAD_TOL = 1e-4;
STEP1_SIZE = 0.1;

fprintf('\n--- Phase 1: angle-only (step=%.2g) ---\n', STEP1_SIZE);
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
STEP2_SIZE = 0.05;

fprintf('\n--- Phase 2: joint angle+radius (step=%.2g) ---\n', STEP2_SIZE);
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

plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor, 'Best phase-2 result', 'final');
fprintf('\nUsing BEST phase-2 configuration found (spread=%.6f), not necessarily the last step.\n', bestSpread);
disp(info);

fprintf('\nDone. Final: nExtrema=%d, weightedDev spread=%.6f, r=%s\n', ...
    info.nExtrema, bestSpread, mat2str(clusterR,4));
fprintf('theta (cycles) = %s\n', mat2str(clusterTheta/(2*pi), 4));

a = 1; % final state left in clusterTheta/clusterR/info for inspection

function plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor, label, tag)
  wiVec = repelem(clusterR, clusterCount) .* exp(1j*repelem(clusterTheta, clusterCount));
  eq = eqlzrDClass(wiVec(:), 1);
  Heq = eq.applyTo(H);
  [~, stats] = estAllPassOrder(H, wp_);
  f = stats.f(:);
  w = 2*pi*f;
  [~, ~, gdH0] = AnlzDH(H, w);
  [~, ~, gdH1] = AnlzDH(Heq, w);
  idx_nom = f >= wp_(1) & f <= wp_(2);

  p2pNomBefore = max(gdH0(idx_nom)) - min(gdH0(idx_nom));
  p2pNomAfter = max(gdH1(idx_nom)) - min(gdH1(idx_nom));
  p2pExpBefore = max(gdH0) - min(gdH0);
  p2pExpAfter = max(gdH1) - min(gdH1);
  fprintf('[%s] %d clusters, r=[%s]: p2p nominal before=%.2f after=%.2f | expanded before=%.2f after=%.2f\n', ...
      label, length(clusterTheta), mat2str(clusterR,3), p2pNomBefore, p2pNomAfter, p2pExpBefore, p2pExpAfter);

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
  title(sprintf('%s: %d clusters, r=[%s]: p2p nominal=%.2f expanded=%.2f', ...
      label, length(clusterTheta), mat2str(clusterR,3), p2pNomAfter, p2pExpAfter));
  grid on;

  if nargin >= 8 && ~isempty(tag)
    figDir = fullfile(fileparts(mfilename('fullpath')), 'Figures');
    if ~exist(figDir, 'dir')
      mkdir(figDir);
    end
    outFile = fullfile(figDir, sprintf('eqlz_csc_newton_1_8_0_%s', tag));
    print(fig, outFile, '-dpng');
    fprintf('Saved plot: %s.png\n', outFile);
  end
end
