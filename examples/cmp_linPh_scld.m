% Compares the original dig_linPh examples with their _scld copies (see
% ScldGD.md). For each pair it prints the final filter's passband
% group-delay ripple, its passband-edge loss against the Ap spec, and its
% minimum stopband loss. Each example runs in its own function workspace
% with figures hidden, so this takes a few minutes.

names = {'0_2_0', '1_2_0', '1_4_0', '1_6_0', '1_8_0'};
fprintf('%-22s %12s %10s %12s %12s\n', 'example', 'GD ripple %', 'Ap dB', ...
    'passband dB', 'min stop dB');
for iName = 1:numel(names)
    for suffix = {'', '_scld'}
        ex = ['dig_linPh_' names{iName} suffix{1}];
        r = measureExample(ex);
        fprintf('%-22s %12.2f %10.2f %12.2f %12.2f\n', ex, r.gdRipple, r.Ap, ...
            r.passLoss, r.stopLoss);
    end
end
a = 1;

function r = measureExample(ex)
%   runs example script ex in this function's workspace and measures the
%   H it designs over its own wp and ws
    figVis = get(0, 'DefaultFigureVisible');
    set(0, 'DefaultFigureVisible', 'off');
    warnState = warning('off', 'all');
    try
        [~] = evalc(ex);
    catch ME
        set(0, 'DefaultFigureVisible', figVis);
        warning(warnState);
        rethrow(ME);
    end
    close all;
    set(0, 'DefaultFigureVisible', figVis);
    warning(warnState);

    f = linspace(wp(1), wp(2), 2001);
    [lg, ~, gd] = AnlzDH(H, 2*pi*f);
    ws1 = max(ws(ws < wp(1)));
    ws2 = min(ws(ws > wp(2)));
    fs = [linspace(-0.5, ws1, 4000) linspace(ws2, 0.5, 4000)];
    lgs = AnlzDH(H, 2*pi*fs);
    toDb = -20/log(10);
    r.gdRipple = 100*(max(gd) - min(gd))/mean(gd);
    r.Ap = Ap;
    r.passLoss = toDb*(min(lg) - max(lg));
    r.stopLoss = toDb*max(lgs - max(lg));
end
