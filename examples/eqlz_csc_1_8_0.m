% Manual/interactive group-delay equalizer exploration for the csc_fltr_1_8_0
% reference filter. Same approach as dsgnEqlzrD_manual.m -- three clusters
% of first-order all-pass stages (same r within each cluster) placed at
% fixed fractions across the passband, plots the complete transfer
% function (magnitude/phase/group-delay), then drops into a keyboard
% breakpoint so additional stages can be added by hand and re-plotted from
% the command line before continuing.
%
% Unlike dsgnEqlzrD_manual.m's narrow passband centered at dc (wp_ = [-0.025
% 0.025]), csc_fltr_1_8_0.m's passband spans almost all positive
% frequencies (wp_ = [0.025 0.475], see csc_fltr_1_8_0.m for the spec
% comments). The three cluster fractions (0.15/0.54/0.90 of the passband)
% are unchanged, so the initial equalizer pole frequencies are spread over
% this much wider band automatically.
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

% Same design specification as csc_fltr_1_8_0.m: 8 movable poles, 1 pole at
% infinity, 0 fixed poles, wp = 0.025 to 0.475, 0.05dB elliptic passband.
% A positive-pass filter passing almost all positive frequencies and no
% negative frequencies.
p = [-0.45 -0.40 -0.35 -0.30 0.3 0.35 0.4 0.45]; % initial guess at finite loss poles
ni = 1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.225; % lower passband edge
wp(2) = 0.225; % upper passband edge
ws = [-0.49 -0.25 0.25 0.49];
as = [50 50 50 50];
Ap = 0.05; % the passband ripple in dB
px = [];
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.25);

cscdFltr1 = dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
H = cscdFltr1.getSystem();

% Three groups of 5 first-order stages in cascade, spread across the
% passband at the same 15%/54%/90% fractions as dsgnEqlzrD_manual.m --
% since wp_ is now much wider, the resulting angles are spread over most
% of the positive frequencies rather than clustered near dc.
f_q1 = wp_(1) + 0.12*diff(wp_);
f_q2 = wp_(1) + 0.30*diff(wp_);
f_q3 = wp_(1) + 0.50*diff(wp_);
f_q4 = wp_(1) + 0.70*diff(wp_);
f_q5 = wp_(1) + 0.88*diff(wp_);
theta_q1 = 2*pi*f_q1;
theta_q2 = 2*pi*f_q2;
theta_q3 = 2*pi*f_q3;
theta_q4 = 2*pi*f_q4;
theta_q5 = 2*pi*f_q5;
r_val2 = 0.830;   % center cluster
r_edge1 = 0.830;  % 15% and 90% clusters
r_edge3 = 0.830;  % 15% and 90% clusters
r_ = 0.82;

wiVec = [repmat(r_*exp(1j*theta_q1), 1, 5), ...
         repmat(r_*exp(1j*theta_q2), 1, 5), ...
         repmat(r_*exp(1j*theta_q3), 1, 5), ...
         repmat(r_*exp(1j*theta_q4), 1, 5), ...
         repmat(r_*exp(1j*theta_q5), 1, 5)];
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
