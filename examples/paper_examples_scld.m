% Regenerates the numbers recommended for a paper on group-delay optimization
% of complex digital filters (see ScldGD.md section 11). Each example runs in
% its own function workspace with figures hidden, and its final filter is
% measured over its own passband wp and stopband ws:
%   GD p2p      peak-to-peak group delay over wp (samples, and % of its mean)
%   pass loss   magnitude variation over wp (dB), against the Ap spec
%   stop loss   minimum stopband loss relative to the passband peak (dB)
%   Ap band     for the equiGd designs, the half-width of the band within Ap
%               of the peak, as a fraction of wp's half-width, and the loss
%               at the wp edge
%
% Part 1: direct equi-ripple-group-delay designs (dig_linPh, original vs _scld)
% Part 2: dig_equiGd series (original vs _scld; the originals are broken by
%         the Nyquist group-delay extremum, ScldGD.md section 11)
% Part 3: all-pass equalizers on the dsgnEqlzrD_manual filter, and EqualFltr_1_6_0
% Part 4: the band-shrinking studies (shrink_eqlzr_scld, shrink_peakNewton_scld,
%         shrink_band_scld), controlled by the flags below.
% Parts 1-3 take about 10 minutes; part 4 adds about 10 more.

RUN_EQUALIZER_SHRINK = true;  % shrink_eqlzr_scld and shrink_peakNewton_scld
RUN_FILTER_SHRINK = true;     % shrink_band_scld

figVis = get(0, 'DefaultFigureVisible'); warnState = warning;
hdr = @(t) fprintf('\n==== %s ====\n', t);
row = @(name, r) fprintf('%-28s %5d %9.3g %9.4g %8.2f%% %9.2f %6.2f %9.1f %9.2g\n', ...
    name, r.order, r.bw, r.p2p, r.p2pRel, r.pass, r.Ap, r.stop, r.dist);
cols = sprintf('%-28s %5s %9s %9s %9s %9s %6s %9s %9s\n', 'example', 'order', ...
    'width', 'GD p2p', 'GD p2p', 'pass dB', 'Ap', 'stop dB', '1-max|p|');

%% Part 1
hdr('Part 1: direct equi-ripple group-delay designs (dig_linPh)');
fprintf('%s', cols);
for ex = {'dig_linPh_1_6_0', 'dig_linPh_1_6_0_scld', 'dig_linPh_1_8_0', ...
        'dig_linPh_1_8_0_scld', 'dig_linPh_1_2_0b'}
    row(ex{1}, measureExample(ex{1}, 'H'));
end

%% Part 2
hdr('Part 2: dig_equiGd series, original vs _scld');
fprintf('%s', strrep(cols, newline, sprintf('  %9s %9s\n', 'Ap band', 'wp-edge dB')));
equiGd = {'1_6_0', '1_10_0', '1_12_0', '1_15_0', '15_0_0', '3_4_0', '3_10_0', '5_0_0', '5_10_0'};
for i = 1:numel(equiGd)
    for suffix = {'', '_scld'}
        ex = ['dig_equiGd_' equiGd{i} suffix{1}];
        r = measureExample(ex, 'H');
        fprintf('%-28s %5d %9.3g %9.4g %8.2f%% %9.2f %6.2f %9.1f %9.2g  %9.2f %9.2f\n', ex, ...
            r.order, r.bw, r.p2p, r.p2pRel, r.pass, r.Ap, r.stop, r.dist, r.apBand, r.edgeLoss);
    end
end

%% Part 3
hdr('Part 3: all-pass equalizers');
fprintf('dsgnEqlzrD_manual filter (5 sections for dsgnEqlzrD / dsgnEqlzrDX_scld):\n');
[H, wp_] = manualFilter();
fn = linspace(wp_(1), wp_(2), 4001);
p2pPct = @(Hf) p2pOver(Hf, fn);
fprintf('  %-34s GD p2p %8.2f%%\n', 'unequalized', p2pPct(H));
[~, eqA] = evalc('dsgnEqlzrD(H, wp_, 5)');
fprintf('  %-34s GD p2p %8.2f%%\n', 'dsgnEqlzrD', p2pPct(eqA.applyTo(H)));
[~, eqB] = evalc('dsgnEqlzrDX_scld(H, wp_, 5)');
fprintf('  %-34s GD p2p %8.2f%%\n', 'dsgnEqlzrDX_scld', p2pPct(eqB.applyTo(H)));
fprintf(['  (eqlzrD_peakNewtonStep with 25 stages: see the 5e-02 rows of ' ...
    'shrink_peakNewton_scld in part 4)\n']);
fprintf('\nEqualFltr_1_6_0 (cascade design):\n');
fprintf('%s', cols);
row('EqualFltr_1_6_0', measureExample('EqualFltr_1_6_0', 'cscdFltr1'));

%% Part 4
if RUN_EQUALIZER_SHRINK
    hdr('Part 4a: shrink_eqlzr_scld (dsgnEqlzrD family vs band width)');
    shrink_eqlzr_scld
    hdr('Part 4b: shrink_peakNewton_scld (eqlzrD_peakNewtonStep vs band width)');
    shrink_peakNewton_scld
end
if RUN_FILTER_SHRINK
    hdr('Part 4c: shrink_band_scld (filter design vs band width)');
    shrink_band_scld
end
set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;

function r = measureExample(ex, varName)
%   runs example script ex in this workspace and measures the filter in
%   variable varName (an lti system, or a cascade object with getSystem)
    set(0, 'DefaultFigureVisible', 'off'); warning('off', 'all');
    [~] = evalc(ex);
    close all;
    F = eval(varName);
    if ~isa(F, 'lti')
        F = F.getSystem();
    end
    if exist('wp_', 'var'), wpM = wp_; else, wpM = wp; end
    if exist('ws_', 'var'), wsM = ws_; else, wsM = ws; end
    r = measureFilter(F, wpM, wsM, Ap);
end

function r = measureFilter(H, wp, ws, Ap)
    toDb = 20/log(10);
    f = linspace(wp(1), wp(2), 4001);
    [lg, ~, gd] = AnlzDH(H, 2*pi*f);
    r.bw = diff(wp);
    r.p2p = max(gd) - min(gd);
    r.p2pRel = 100*r.p2p/mean(gd);
    r.pass = toDb*(max(lg) - min(lg));
    r.Ap = Ap;
    ws1 = max(ws(ws < wp(1)));
    ws2 = min(ws(ws > wp(2)));
    fs = [linspace(-0.5, ws1, 4000) linspace(ws2, 0.5, 4000)];
    r.stop = -toDb*max(AnlzDH(H, 2*pi*fs) - max(lg));
    r.dist = 1 - max(abs(pole(H)));
    r.order = numel(pole(H));
    % band within Ap of the passband peak, relative to wp's half-width
    fc = mean(wp);
    fw = linspace(wp(1) - diff(wp), wp(2) + diff(wp), 12001);
    lw = toDb*(AnlzDH(H, 2*pi*fw) - max(lg));
    inAp = fw(lw >= -Ap);
    r.apBand = max(abs(inAp - fc))/(diff(wp)/2);
    r.edgeLoss = -toDb*(min(lg([1 end])) - max(lg));
end

function [H, wp_] = manualFilter()
%   the dsgnEqlzrD_manual / dsgnEqlzrD_peakNewton_manual filter
    p = [-0.35 -0.25 -0.1 -0.08 0.25 0.35];
    ni = 1; px = []; as = [70 50 50 70]; Ap = 0.05;
    wp = [-0.025 0.025]; ws = [-0.49 -0.049 0.049 0.49];
    [p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
    set(0, 'DefaultFigureVisible', 'off'); warning('off', 'all');
    [~, cscd] = evalc('dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, ''elliptic'')');
    close all;
    H = cscd.getSystem();
end

function v = p2pOver(H, f)
    [~, ~, g] = AnlzDH(H, 2*pi*f);
    v = 100*(max(g) - min(g))/mean(g);
end
