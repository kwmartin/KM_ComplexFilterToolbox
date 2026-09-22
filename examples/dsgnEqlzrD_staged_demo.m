% Demo/test script for lib/dsgnEqlzrD.m's staged-heuristic alternative,
% examples/dsgnEqlzrD_staged.m. Builds the same cascade filter as
% csc_fltr_1_6_0.m, designs a staged group-delay equalizer for it, and
% plots group delay before/after (full expanded analysis band, and
% zoomed to the nominal passband) so the peaks/valleys can be inspected
% before deciding how to refine the method.

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

N_est = 5;
[eqS, infoS] = dsgnEqlzrD_staged(H, wp_, N_est);
fprintf('staged: p2p_before=%.4f p2p_after=%.4f worstResidual=%.4f r_shared=%.4f wallTime=%.3fs\n', ...
    infoS.p2p_before, infoS.p2p_after, infoS.worstResidual, infoS.r_shared, infoS.wallTime);

[~, stats] = estAllPassOrder(H, wp_);
f = stats.f(:);
w = 2*pi*f;
gdH0 = stats.gdH(:);
D_target = infoS.D_target;

Heq = eqS.applyTo(H);
[~, ~, gdH1] = AnlzDH(Heq, w);

fig1 = figure('Position', [100 100 900 500]);
plot(f, gdH0, 'b', 'LineWidth', 1.2); hold on;
plot(f, gdH1, 'r', 'LineWidth', 1.2);
plot(f, D_target*ones(size(f)), 'k--');
xline(wp_(1), ':k'); xline(wp_(2), ':k');
for i = 1:N_est
  xline(angle(eqS.sctns(i).wi)/(2*pi), 'g:');
end
legend('unequalized gdH', 'equalized gdH (staged)', 'D_{target}', 'nominal wp edges', 'pole angles', 'Location', 'best');
xlabel('f (cycles)'); ylabel('group delay (samples)');
title(sprintf('Staged equalizer, N=%d: p2p before=%.2f after=%.2f (expanded band)', ...
    N_est, max(gdH0)-min(gdH0), max(gdH1)-min(gdH1)));
grid on;
print(fig1, '../examples/Figures/dsgnEqlzrD_staged_demo', '-dpng');

idx = f >= wp_(1) & f <= wp_(2);
fig2 = figure('Position', [100 100 900 500]);
plot(f(idx), gdH0(idx), 'b', 'LineWidth', 1.2); hold on;
plot(f(idx), gdH1(idx), 'r', 'LineWidth', 1.2);
plot(f(idx), D_target*ones(size(f(idx))), 'k--');
legend('unequalized gdH', 'equalized gdH (staged)', 'D_{target}', 'Location', 'best');
xlabel('f (cycles)'); ylabel('group delay (samples)');
title(sprintf('Zoomed to nominal passband: p2p before=%.2f after=%.2f', ...
    max(gdH0(idx))-min(gdH0(idx)), max(gdH1(idx))-min(gdH1(idx))));
grid on;
print(fig2, '../examples/Figures/dsgnEqlzrD_staged_demo_zoom', '-dpng');

a = 1;
