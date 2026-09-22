% Interactive, one-iteration-at-a-time driver for
% eqlzrD_peakNewtonStep.m. Starts from the 3-cluster (15%/54%/90%,
% r=0.925, 5 stages each) configuration explored by hand in
% dsgnEqlzrD_manual.m, then repeatedly calls eqlzrD_peakNewtonStep to
% adjust the three cluster angles (r held fixed) to drive ALL of the
% current group delay's local extrema's gain-weighted deviation from the
% anchor toward equality (not just the original two edge peaks -- see
% eqlzrD_peakNewtonStep.m's own header for why that was wrong).
%
% Run this once to set up and take the FIRST step, inspect the plot and
% "info" struct at the breakpoint, then repeat the call shown in the
% fprintf message below as many times as you like -- each call takes
% exactly one damped Newton step and returns updated diagnostics.

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
% adjustable, r fixed).
clusterTheta = 2*pi*[wp_(1)+0.15*diff(wp_), wp_(1)+0.54*diff(wp_), wp_(1)+0.90*diff(wp_)];
clusterR = [0.925, 0.925, 0.925];
clusterCount = [5, 5, 5];

plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);

fprintf('\nInitial setup plotted. anchor=%.4f\n', anchor);
fprintf('Taking the first Newton step now...\n');

% eqlzrD_peakNewtonStep re-detects the FULL current extremum set (every
% local max/min, not just the two original edge peaks) fresh every call,
% via zero crossings of d2TdW on a 500-point grid over wp_ expanded 10%
% each side -- see the function's own header for why this replaced the
% earlier fixed-2-peak version.
[clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_);
disp(info);
plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);

fprintf('\nStep 1 done. nExtrema=%d, weightedDev spread %.3f -> ~%.3f\n', ...
    info.nExtrema, info.spreadBefore, info.spreadAfter);
fprintf('To take another step, run at this prompt:\n');
fprintf('  [clusterTheta, info] = eqlzrD_peakNewtonStep(H, clusterTheta, clusterR, clusterCount, anchor, wp_);\n');
fprintf('  plotCurrent(H, clusterTheta, clusterR, clusterCount, wp_, anchor);\n');
fprintf('Repeat as many times as you like. Type dbcont to finish, dbquit to abort.\n');
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
  title(sprintf('%d clusters, r=[%s]: p2p before=%.2f after=%.2f (expanded)', ...
      length(clusterTheta), mat2str(clusterR,3), max(gdH0)-min(gdH0), max(gdH1)-min(gdH1)));
  grid on;
end
