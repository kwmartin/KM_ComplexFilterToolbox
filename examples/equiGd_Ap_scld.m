% Re-runs the 9 dig_equiGd specs with the passband edge held at wp
% (equiGdDigital_scld inside the equiGdDigitalAp_scld outer loop), with the
% stopband edges moved to 4x and 6x the passband half-width. The original
% specs put ws at only 2x wp (12.8x for 3_4_0), where Ap at wp and the
% stopband cannot both be met at these orders. See Eqlzr_scld_results.md.
%
% For each spec it prints:
%   base    equiGdDigital_scld once, with the original ws (as in the
%           dig_equiGd_*_scld examples)
%   Ap, ws=Rx  equiGdDigitalAp_scld with ws = R x wp's half-width about the
%           band centre
% Columns: k (design-band factor), Ap band (half-width within Ap of the
% peak / wp half-width; 1 means the Ap edge is at wp), loss at the wp edge,
% GD p2p over wp, minimum stopband loss, designs run. Loss poles that would
% fall inside the new transition band are moved just outside it, keeping
% their order (noted with *). Takes about 10 minutes.

figVis = get(0, 'DefaultFigureVisible'); warnState = warning;
set(0, 'DefaultFigureVisible', 'off'); warning('off', 'all');

N = 64;
% name, p, ni, wp, original ws, Ap, useWs (the equiGdDigital call of each script)
specs = {
    '1_6_0',  [-0.3 -0.25 -0.15 0.15 0.25 0.3], 1, [-0.5/N 0.5/N], [-0.499 -1/N 1/N 0.499], 1.0, 1
    '1_10_0', [-0.3 -0.25 -0.2 -0.15 -0.1 0.1 0.15 0.2 0.25 0.3], 1, [-0.5/N 0.5/N], [-0.499 -1/N 1/N 0.499], 3.0103, 1
    '1_12_0', [-0.3 -0.25 -0.2 -0.15 -0.12 0.12 0.15 0.2 0.25 0.3], 1, [-0.05 0.05], [-0.499 -0.1 0.1 0.499], 3.0103, 1
    '1_15_0', [-0.4 -0.3 -0.25 -0.2 -0.15 -0.12 0.12 0.15 0.2 0.25 0.3 0.4], 1, [-0.05 0.05], [-0.499 -0.1 0.1 0.499], 3.0103, 1
    '15_0_0', [-0.4 -0.2 0.2 0.4], 7, [-0.05 0.05], [-0.499 -0.1 0.1 0.499], 3.0103, 0
    '3_4_0',  [-0.4 -0.3 -0.25 -0.2 -0.15 0.15 0.2 0.25 0.3 0.4], 1, [-0.5/N 0.5/N], [-0.499 -0.1 0.1 0.499], 1.0, 0
    '3_10_0', [-0.3 -0.25 -0.2 -0.15 -0.1 0.1 0.15 0.2 0.25 0.3], 3, [-0.5/N 0.5/N], [-0.499 -1/N 1/N 0.499], 3.0103, 1
    '5_0_0',  [], 15, [-0.05 0.05], [-0.499 -0.1 0.1 0.499], 3.0103, 1
    '5_10_0', [-0.4 -0.3 -0.25 -0.2 -0.15 0.15 0.2 0.25 0.3 0.4], 5, [-0.05 0.05], [-0.499 -0.1 0.1 0.499], 3.0103, 1
    };
as = [20 20 20 20]; px = []; deltGD = 0.25;

fprintf('%-8s %-12s %6s %8s %9s %9s %9s %6s\n', 'spec', 'variant', 'k', ...
    'Ap band', 'edge dB', 'GD p2p%', 'stop dB', 'runs');
for i = 1:size(specs, 1)
    [nm, p, ni, wp, ws0, Ap, useWs] = specs{i, :};
    fc = mean(wp); hw = diff(wp)/2;
    % baseline: one pass of equiGdDigital_scld with the original ws
    try
        [~, H] = evalc('equiGdDigital_scld(p, px, ni, wp, ws0, as, Ap, deltGD, useWs)');
        r = measure(H, wp, ws0, Ap);
        fprintf('%-8s %-12s %6.3f %8.3f %9.2f %9.2f %9.1f %6d\n', nm, 'base', 1, ...
            r.apBand, r.edgeLoss, r.gdP2pPct, r.stopLoss, 1);
    catch ME
        fprintf('%-8s %-12s ERROR %s\n', nm, 'base', ME.message);
    end
    for R = [4 6]
        ws = [-0.499, fc - R*hw, fc + R*hw, 0.499];
        [pR, moved] = clearTransition(p, ws(2), ws(3));
        label = sprintf('Ap, ws=%dx%s', R, repmat('*', 1, moved));
        try
            [~, H, info] = evalc('equiGdDigitalAp_scld(pR, px, ni, wp, ws, as, Ap, deltGD, useWs)');
            fprintf('%-8s %-12s %6.3f %8.3f %9.2f %9.2f %9.1f %6d\n', nm, label, info.k, ...
                info.apBand, info.edgeLoss, info.gdP2pPct, info.stopLoss, info.iters);
        catch ME
            fprintf('%-8s %-12s ERROR %s\n', nm, label, ME.message);
        end
    end
end
set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;

function [p, moved] = clearTransition(p, wsLo, wsHi)
%   moves loss poles inside (wsLo, wsHi) just outside it, spreading each
%   side's poles evenly from 1.05x the edge out to the side's outermost
%   pole (or 0.47), so their order is kept
    moved = any(p > wsLo & p < wsHi);
    if ~moved, return, end
    for side = [-1 1]
        idx = find(sign(p) == side);
        if isempty(idx), continue, end
        edge = abs([wsLo wsHi]); edge = edge((side + 3)/2);
        outer = max(max(abs(p(idx))), 1.2*edge);
        outer = min(outer, 0.47);
        [~, ord] = sort(abs(p(idx)));
        mags = linspace(1.05*edge, outer, numel(idx));
        p(idx(ord)) = side*mags;
    end
end

function r = measure(H, wp, ws, Ap)
    toDb = 20/log(10);
    H.k = H.k/abs(freqresp(H, 2*pi*mean(wp)));
    f = linspace(wp(1), wp(2), 4001);
    [lg, ~, gd] = AnlzDH(H, 2*pi*f);
    fw = linspace(wp(1) - diff(wp), wp(2) + diff(wp), 12001);
    lw = toDb*(AnlzDH(H, 2*pi*fw) - max(lg));
    r.apBand = max(abs(fw(lw >= -Ap) - mean(wp)))/(diff(wp)/2);
    r.edgeLoss = -toDb*(min(lg([1 end])) - max(lg));
    r.gdP2pPct = 100*(max(gd) - min(gd))/mean(gd);
    ws1 = max(ws(ws < wp(1))); ws2 = min(ws(ws > wp(2)));
    fs = [linspace(-0.5, ws1, 4000) linspace(ws2, 0.5, 4000)];
    r.stopLoss = -toDb*max(AnlzDH(H, 2*pi*fs) - max(lg));
end
