% Makes the paper's magnitude and group-delay figures with plotMgTwo and
% plotGdTwo: each figure shows the final design only, as two solid curves
% in one axes box: the passband zoom and the full band, in the same units
% (dB for magnitude, samples for group delay). Band-edge markers are off. Writes doc/figures/<name>.pdf (for the pdflatex build) and
% .png (for the HTML build); doc/CmplxFltrGrpDly.md refers to them as
% figures/<name> with no extension (tools/render_paper.py picks the type).
%
% Each example gets ONE combined figure (combinedMagGdFig, below):
% magnitude on the left, group delay on the right (one curve, or two
% overlaid by colour for a before/after comparison), each panel about
% half a column wide -- see ReductionPlan.md's "Figure strategy for
% Section VI". This replaced one magnitude + one-or-two group-delay
% figures per example.
%
%   fig_m1_combined   Method 1, dig_equiGd 1_10_0: the design with Ap
%                      held at wp (equiGdDigitalAp_scld, ws = 6x wp), as
%                      in the paper's section 6.1 table. No before/after:
%                      one curve in each panel.
%   fig_m2_combined    Method 2: magnitude (unchanged by the all-pass
%                      equalizer, so shown once) and group delay before
%                      and after equalization, overlaid, of
%                      dsgnEqlzrD_peakNewton_manual's filter (5 clusters
%                      of 5 sections, the same two-phase schedule)
%   fig_m2w_combined   Method 2 on the wide-band filter csc_fltr_1_8_0
%                      (passband 0.025-0.475 Hz): magnitude, and group
%                      delay before/after overlaid, equalization with 7
%                      clusters of 5 sections (eqlz_csc_newton_1_8_0's
%                      schedule)
%
% Takes about 5 minutes (mostly the Ap loop).

figVis = get(0, 'DefaultFigureVisible'); warnState = warning;
set(0, 'DefaultFigureVisible', 'off'); warning('off', 'all');
here = fileparts(mfilename('fullpath'));
figDir = fullfile(here, '..', 'doc', 'figures');

%% Method 1: dig_equiGd 1_10_0, base against Ap held at wp
N = 64;
p = [-0.3 -0.25 -0.2 -0.15 -0.1 0.1 0.15 0.2 0.25 0.3];
ni = 1; px = []; as = [20 20 20 20]; Ap = 3.0103; deltGD = 0.25; useWs = 1;
wp = [-0.5/N 0.5/N];
hw = diff(wp)/2;
ws6 = [-0.499 -6*hw 6*hw 0.499];
[~, Hap, info] = evalc('equiGdDigitalAp_scld(p, px, ni, wp, ws6, as, Ap, deltGD, useWs)');
fprintf('1_10_0 Ap-held: k = %.3f, Ap band = %.3f, edge loss = %.2f dB\n', ...
    info.k, info.apBand, info.edgeLoss);
[~, r] = combinedMagGdFig(Hap, Hap, wp, ws6, Ap, {}, fullfile(figDir, 'fig_m1_combined'));
fprintf('1_10_0 GD p2p over wp: %.2f%%\n', r.p2pPct);

%% Method 2: 5 clusters of 5 all-pass sections (dsgnEqlzrD_peakNewton_manual)
p = [-0.35 -0.25 -0.1 -0.08 0.25 0.35];
ni = 1; px = []; as = [70 50 50 70]; Ap = 0.05;
wp = [-0.025 0.025];
ws = [-0.49 -0.049 0.049 0.49];
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
[~, cscd] = evalc('dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, ''elliptic'')');
H = cscd.getSystem();
[~, stats] = estAllPassOrder(H, wp_);
gdH0 = stats.gdH(:);
anchor = mean(gdH0(islocalmax(gdH0, 'MinProminence', 5)));

clusterTheta = 2*pi*(wp_(1) + linspace(0.10, 0.90, 5)*diff(wp_));
clusterR = 0.925*ones(1, 5);
clusterCount = 5*ones(1, 5);
% phase 1: angles only
spreadPrev = Inf;
for iter = 1:100
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, ...
        clusterR, clusterCount, anchor, wp_, 0.2);
    if abs(info.spreadBefore - spreadPrev) < 1e-4, break, end
    spreadPrev = info.spreadBefore;
end
% phase 2: angles and radii, keeping the best spread seen
best = {info.spreadBefore, clusterTheta, clusterR};
noImprove = 0;
for iter = 1:50
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, ...
        clusterR, clusterCount, anchor, wp_, 0.1, [], true);
    if info.spreadBefore < best{1}
        best = {info.spreadBefore, clusterTheta, clusterR};
        noImprove = 0;
    else
        noImprove = noImprove + 1;
        if noImprove >= 5, break, end
    end
end
[~, clusterTheta, clusterR] = best{:};
wi = repelem(clusterR, clusterCount).*exp(1j*repelem(clusterTheta, clusterCount));
Heq = eqlzrDClass(wi(:), 1).applyTo(H);
[rm, r] = combinedMagGdFig(Heq, {H, Heq}, wp_, ws_, Ap, {'before', 'after'}, ...
    fullfile(figDir, 'fig_m2_combined'));
dBw = rm.dBz(rm.fz >= wp_(1) & rm.fz <= wp_(2));
inStop = rm.f <= 0 | rm.f >= 0.5;
fprintf('Method 2 passband ripple %.3f dB, min stopband loss %.1f dB\n', ...
    -min(dBw), -max(rm.dB(inStop)));
fprintf('Method 2 GD p2p over wp: before %.2f%%, after %.2f%%\n', r.p2pPct(1), r.p2pPct(2));

%% Method 2, wide band: csc_fltr_1_8_0, 7 clusters of 5 (eqlz_csc_newton_1_8_0)
p = [-0.45 -0.40 -0.35 -0.30 0.3 0.35 0.4 0.45];
ni = 1; px = []; as = [50 50 50 50]; Ap = 0.05;
wp = [-0.225 0.225];
ws = [-0.49 -0.25 0.25 0.49];
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.25);
[~, cscd] = evalc('dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, ''elliptic'')');
H = cscd.getSystem();
[~, stats] = estAllPassOrder(H, wp_);
gdH0 = stats.gdH(:);
anchor = mean(gdH0(islocalmax(gdH0, 'MinProminence', 5)));

clusterTheta = 2*pi*(wp_(1) + linspace(0.10, 0.90, 7)*diff(wp_));
clusterR = 0.78*ones(1, 7);
clusterCount = 5*ones(1, 7);
spreadPrev = Inf;
for iter = 1:100
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, ...
        clusterR, clusterCount, anchor, wp_, 0.1);
    if abs(info.spreadBefore - spreadPrev) < 1e-4, break, end
    spreadPrev = info.spreadBefore;
end
best = {info.spreadBefore, clusterTheta, clusterR};
noImprove = 0;
for iter = 1:50
    [clusterTheta, clusterR, info] = eqlzrD_peakNewtonStep(H, clusterTheta, ...
        clusterR, clusterCount, anchor, wp_, 0.05, [], true);
    if info.spreadBefore < best{1}
        best = {info.spreadBefore, clusterTheta, clusterR};
        noImprove = 0;
    else
        noImprove = noImprove + 1;
        if noImprove >= 5, break, end
    end
end
[~, clusterTheta, clusterR] = best{:};
wi = repelem(clusterR, clusterCount).*exp(1j*repelem(clusterTheta, clusterCount));
Heq = eqlzrDClass(wi(:), 1).applyTo(H);
[rm, r] = combinedMagGdFig(Heq, {H, Heq}, wp_, ws_, Ap, {'before', 'after'}, ...
    fullfile(figDir, 'fig_m2w_combined'));
inWp = r.fz >= wp_(1) & r.fz <= wp_(2);
fprintf('csc_fltr_1_8_0 before equalization: GD over wp %.2f-%.2f samples\n', ...
    min(r.gdz(inWp, 1)), max(r.gdz(inWp, 1)));
fe = stats.f(:);
[~, ~, gdUe] = AnlzDH(H, 2*pi*fe);
[~, ~, gdEe] = AnlzDH(Heq, 2*pi*fe);
gE = r.gdz(inWp, 2);
fprintf(['csc_fltr_1_8_0, 7 clusters: GD over wp %.2f-%.2f samples (mean %.2f), ' ...
    'p2p %.2f samples (%.2f%%); unequalized p2p %.2f samples\n'], min(gE), max(gE), ...
    mean(gE), max(gE) - min(gE), r.p2pPct(2), max(r.gdz(inWp, 1)) - min(r.gdz(inWp, 1)));
fprintf('  expanded band %.3f-%.3f Hz: p2p %.2f samples (unequalized %.2f)\n', ...
    fe(1), fe(end), max(gdEe) - min(gdEe), max(gdUe) - min(gdUe));
fprintf('  radii %s\n', mat2str(clusterR, 3));
dBw = rm.dBz(rm.fz >= wp_(1) & rm.fz <= wp_(2));
inStop = rm.f <= 0 | rm.f >= 0.5;
fprintf('  passband ripple %.3f dB, min stopband loss %.1f dB\n', -min(dBw), -max(rm.dB(inStop)));

set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;
