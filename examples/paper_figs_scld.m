% Makes the paper's magnitude and group-delay figures with plotMgTwo and
% plotGdTwo: each figure shows the full band and a passband zoom in one
% axes box. Writes doc/figures/<name>.pdf (for the pdflatex build) and
% .png (for the HTML build); doc/CmplxFltrGrpDly.md refers to them as
% figures/<name> with no extension (tools/render_paper.py picks the type).
%
%   fig_m1_mag, fig_m1_gd  Method 1, dig_equiGd 1_10_0: the base design
%                          (equiGdDigital_scld, original ws = 2x wp) against
%                          the Ap-held design (equiGdDigitalAp_scld,
%                          ws = 6x wp), as in the paper's section 6.1 table;
%                          the GD zoom shows each design's % deviation from
%                          its own mean, since their delays differ (~243 vs
%                          ~123 samples)
%   fig_m2_gd              Method 2: unequalized against equalized group
%                          delay for dsgnEqlzrD_peakNewton_manual's filter
%                          (5 clusters of 5 sections, the same two-phase
%                          schedule). D0 is not marked: equalization adds
%                          delay, so the equalized curve sits far above it.
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
ws0 = [-0.499 -1/N 1/N 0.499];
hw = diff(wp)/2;
ws6 = [-0.499 -6*hw 6*hw 0.499];
[~, Hbase] = evalc('equiGdDigital_scld(p, px, ni, wp, ws0, as, Ap, deltGD, useWs)');
[~, Hap, info] = evalc('equiGdDigitalAp_scld(p, px, ni, wp, ws6, as, Ap, deltGD, useWs)');
fprintf('1_10_0 Ap-held: k = %.3f, Ap band = %.3f, edge loss = %.2f dB\n', ...
    info.k, info.apBand, info.edgeLoss);
names = {'base, ws = 2x', 'A_p held, ws = 6x'};
plotMgTwo({Hbase, Hap}, wp, ws6, struct('names', {names}, 'Ap', Ap, ...
    'file', fullfile(figDir, 'fig_m1_mag')));
[~, ~, r] = plotGdTwo({Hbase, Hap}, wp, ws6, struct('names', {names}, ...
    'maskDb', 120, 'zoomRelPct', true, 'file', fullfile(figDir, 'fig_m1_gd')));
fprintf('1_10_0 GD p2p over wp: base %.2f%%, Ap-held %.2f%%\n', r.p2pPct);

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
[~, ~, r] = plotGdTwo({H, Heq}, wp_, ws_, struct('names', ...
    {{'unequalized', 'equalized'}}, 'maskDb', 120, ...
    'file', fullfile(figDir, 'fig_m2_gd')));
fprintf('Method 2 GD p2p over wp: unequalized %.2f%%, equalized %.2f%%\n', r.p2pPct);

set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;
