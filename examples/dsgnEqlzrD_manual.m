% Manual/interactive group-delay equalizer exploration. Builds the same
% reference cascade filter used throughout the dsgnEqlzrD*.m exploration,
% places two first-order all-pass stages in cascade at the passband
% center (same r for both), plots the complete transfer function
% (magnitude/phase/group-delay), then drops into a keyboard breakpoint so
% additional stages can be added by hand and re-plotted from the command
% line before continuing.
%
% To add another stage after the breakpoint, e.g.:
%   eq = addSctn(eq, r_val*exp(1j*theta_center));   % another stage at center
%   eq = addSctn(eq, 0.85*exp(1j*(theta_center+0.05)));  % off-center, different r
% then re-run the plot block below (select the lines and evaluate, or
% just call plotStages() again -- see below) to see the updated result.
% Type "dbcont" (or the editor's Continue button) to resume/finish, or
% "dbquit" to abort.

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

% Three groups of 5 first-order stages in cascade: at the passband
% center, and at the 25% and 75% points across the passband. The center
% cluster uses r_val; the two edge clusters (closer to H's own peaks)
% use a separate, higher r_edge -- narrower bumps leak less into the
% peaks. r_q1 and r_q3 are kept equal for now (r_edge) but can be split
% if one side needs different tuning than the other.
f_q2 = wp_(1) + 0.54*diff(wp_);
f_q1 = wp_(1) + 0.15*diff(wp_);
f_q3 = wp_(1) + 0.90*diff(wp_);
theta_q1 = 2*pi*f_q1;
theta_q2 = 2*pi*f_q2;
theta_q3 = 2*pi*f_q3;
r_val2 = 0.925;   % center cluster
r_edge1 = 0.925;  % 25% and 75% clusters
r_edge3 = 0.925;  % 25% and 75% clusters

wiVec = [repmat(r_val2*exp(1j*theta_q2), 1, 5), ...
         repmat(r_edge1*exp(1j*theta_q1), 1, 5), ...
         repmat(r_edge3*exp(1j*theta_q3), 1, 5)];
eq = eqlzrDClass(wiVec, 1);
disp(eq);

plotStages(H, eq, wp_);

fprintf('\nPaused at breakpoint. Inspect/modify "eq" (e.g. addSctn(eq, r*exp(1j*theta))),\n');
fprintf('then call plotStages(H, eq, wp_) again to see the updated result.\n');
fprintf('Type dbcont to resume, dbquit to abort.\n');
keyboard

a = 1; % execution resumes here after "dbcont"

function plotStages(H, eq, wp_)
  Heq = eq.applyTo(H);
  [~, stats] = estAllPassOrder(H, wp_);
  f = stats.f(:);
  w = 2*pi*f;
  [~, ~, gdH0] = AnlzDH(H, w);
  [~, ~, gdH1] = AnlzDH(Heq, w);

  fig = figure('Position', [100 100 900 500]);
  plot(f, gdH0, 'b', 'LineWidth', 1.2); hold on;
  plot(f, gdH1, 'r', 'LineWidth', 1.2);
  xline(wp_(1), ':k'); xline(wp_(2), ':k');
  legend('unequalized gdH', 'equalized gdH', 'nominal wp edges', 'Location', 'best');
  xlabel('f (cycles)'); ylabel('group delay (samples)');
  title(sprintf('%d-section equalizer: p2p before=%.2f after=%.2f (expanded band)', ...
      eq.size, max(gdH0)-min(gdH0), max(gdH1)-min(gdH1)));
  grid on;

  plot_dam_ph_gd(Heq, [wp_(1) wp_(2)], -80, 'r');
end
