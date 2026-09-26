% Makes the paper's magnitude and group-delay figures with plotMgTwo and
% plotGdTwo: each figure shows the final design only, as two solid curves
% in one axes box: the passband zoom and the full band, in the same units
% (dB for magnitude, samples for group delay). Band-edge markers are off. Writes doc/figures/<name>.pdf (for the pdflatex build) and
% .png (for the HTML build); doc/CmplxFltrGrpDly.md refers to them as
% figures/<name> with no extension (tools/render_paper.py picks the type).
%
%   fig_m1_mag, fig_m1_gd  Method 1, dig_equiGd 1_10_0: the design with Ap
%                          held at wp (equiGdDigitalAp_scld, ws = 6x wp), as
%                          in the paper's section 6.1 table
%   fig_m2_mag, fig_m2_gd0, fig_m2_gd  Method 2: magnitude (unchanged by
%                          the all-pass equalizer) and group delay before
%                          and after equalization, of dsgnEqlzrD_peakNewton_
%                          manual's filter (5 clusters of 5 sections, the
%                          same two-phase schedule)
%   fig_m2w_mag, fig_m2w_gd0, fig_m2w_gd  Method 2 on the wide-band filter
%                          csc_fltr_1_8_0 (passband 0.025-0.475 Hz):
%                          magnitude, and group delay before and after
%                          equalization with 7 clusters of 5 sections
%                          (eqlz_csc_newton_1_8_0's schedule)
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
plotMgTwo(Hap, wp, ws6, struct('Ap', Ap, 'markEdges', false, ...
    'file', fullfile(figDir, 'fig_m1_mag')));
[~, ~, r] = plotGdTwo(Hap, wp, ws6, struct('markEdges', false, ...
    'file', fullfile(figDir, 'fig_m1_gd')));
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
[~, ~, r0] = plotGdTwo(H, wp_, ws_, struct('markEdges', false, ...
    'file', fullfile(figDir, 'fig_m2_gd0')));
fprintf('Method 2 GD p2p over wp before equalization: %.2f%%\n', r0.p2pPct);

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
[~, ~, rm] = plotMgTwo(Heq, wp_, ws_, struct('Ap', Ap, 'markEdges', false, ...
    'file', fullfile(figDir, 'fig_m2_mag')));
dBw = rm.dBz(rm.fz >= wp_(1) & rm.fz <= wp_(2));
inStop = rm.f <= 0 | rm.f >= 0.5;
fprintf('Method 2 passband ripple %.3f dB, min stopband loss %.1f dB\n', ...
    -min(dBw), -max(rm.dB(inStop)));
[~, ~, r] = plotGdTwo(Heq, wp_, ws_, struct('markEdges', false, ...
    'file', fullfile(figDir, 'fig_m2_gd')));
fprintf('Method 2 GD p2p over wp after equalization: %.2f%%\n', r.p2pPct);

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
[~, ~, rm] = plotMgTwo(Heq, wp_, ws_, struct('Ap', Ap, 'markEdges', false, ...
    'file', fullfile(figDir, 'fig_m2w_mag')));
[~, ~, r0] = plotGdTwo(H, wp_, ws_, struct('markEdges', false, ...
    'file', fullfile(figDir, 'fig_m2w_gd0')));
fprintf('csc_fltr_1_8_0 before equalization: GD over wp %.2f-%.2f samples\n', ...
    min(r0.gdz(r0.fz >= wp_(1) & r0.fz <= wp_(2))), max(r0.gdz(r0.fz >= wp_(1) & r0.fz <= wp_(2))));
[~, ~, r] = plotGdTwo(Heq, wp_, ws_, struct('markEdges', false, ...
    'file', fullfile(figDir, 'fig_m2w_gd')));
[~, ~, gdU] = AnlzDH(H, 2*pi*r.fz);
inWp = r.fz >= wp_(1) & r.fz <= wp_(2);
fe = stats.f(:);
[~, ~, gdUe] = AnlzDH(H, 2*pi*fe);
[~, ~, gdEe] = AnlzDH(Heq, 2*pi*fe);
gE = r.gdz(inWp);
fprintf(['csc_fltr_1_8_0, 7 clusters: GD over wp %.2f-%.2f samples (mean %.2f), ' ...
    'p2p %.2f samples (%.2f%%); unequalized p2p %.2f samples\n'], min(gE), max(gE), ...
    mean(gE), max(gE) - min(gE), r.p2pPct, max(gdU(inWp)) - min(gdU(inWp)));
fprintf('  expanded band %.3f-%.3f Hz: p2p %.2f samples (unequalized %.2f)\n', ...
    fe(1), fe(end), max(gdEe) - min(gdEe), max(gdUe) - min(gdUe));
fprintf('  radii %s\n', mat2str(clusterR, 3));
dBw = rm.dBz(inWp);
inStop = rm.f <= 0 | rm.f >= 0.5;
fprintf('  passband ripple %.3f dB, min stopband loss %.1f dB\n', -min(dBw), -max(rm.dB(inStop)));

set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;
