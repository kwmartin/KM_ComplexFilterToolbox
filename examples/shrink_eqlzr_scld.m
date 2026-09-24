% Shrinks the dsgnEqlzrD_manual passband (0.05 cycles wide) by factors of
% 10 and compares five N-section all-pass group-delay equalizer designs
% (see ScldGD.md section 8):
%   A  dsgnEqlzrD          - (r, theta) in z, absolute bounds r <= 0.995
%   B  dsgnEqlzrDX_scld    - (sigma, Wp) in the band-centred transformed
%                            variable, bounds in band units
%   C  dsgnEqlzrDZrel_scld - (r, theta) in z, with B's bounds and starts
%                            mapped to r (control: same bounds as B,
%                            different variables)
%   D  dsgnEqlzrDZlin_scld - B's variables linearized back to z:
%                            r = 1 - 2*t*rho, theta = w0 + 2*t*phi (control:
%                            linear band scaling instead of the exact map)
%   E  dsgnEqlzrDZlinB_scld - D with the section group delay evaluated
%                            without cancellation
% For each it prints the peak-to-peak group delay over the nominal and
% expanded (+-10%) passband of the equalized filter, relative to its mean,
% and the largest equalizer pole radius. Takes several minutes.

figVis = get(0, 'DefaultFigureVisible'); warnState = warning;
set(0, 'DefaultFigureVisible', 'off'); warning('off', 'all');

N_SECT = 5;
designs = {'dsgnEqlzrD', 'dsgnEqlzrDX_scld', 'dsgnEqlzrDZrel_scld', 'dsgnEqlzrDZlin_scld', 'dsgnEqlzrDZlinB_scld'};
p = [-0.35 -0.25 -0.1 -0.08 0.25 0.35];
ni = 1; px = []; as = [70 50 50 70]; Ap = 0.05;
fprintf('%-8s %-20s %10s %10s %10s %12s %6s\n', 'width', 'design', ...
    'p2p nom %', 'p2p exp %', 'D', '1-max|pole|', 'time');
for s = [1 1e-1 1e-2 1e-3]
    wp = [-0.025 0.025]*s;
    ws = [-0.49 -0.049*s 0.049*s 0.49];
    [p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
    [~, cscd] = evalc('dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, ''elliptic'')');
    H = cscd.getSystem();
    close all;
    fn = linspace(wp_(1), wp_(2), 4001);
    fe = linspace(wp_(1) - 0.1*diff(wp_), wp_(2) + 0.1*diff(wp_), 4001);
    [~, ~, g0n] = AnlzDH(H, 2*pi*fn);
    [~, ~, g0e] = AnlzDH(H, 2*pi*fe);
    fprintf('%-8.0e %-20s %10.2f %10.2f %10.4g\n', diff(wp_), 'unequalized', ...
        100*(max(g0n) - min(g0n))/mean(g0n), 100*(max(g0e) - min(g0e))/mean(g0e), max(g0e));
    for k = 1:numel(designs)
        try
            t0 = tic;
            [~, eq, info] = evalc([designs{k} '(H, wp_, N_SECT)']);
            el = toc(t0);
            Heq = eq.applyTo(H);
            [~, ~, gn] = AnlzDH(Heq, 2*pi*fn);
            [~, ~, ge] = AnlzDH(Heq, 2*pi*fe);
            [~, pe] = zpkdata(eq.getSystem(), 'vector');
            fprintf('%-8s %-20s %10.3f %10.3f %10.4g %12.3g %5.0fs\n', '', designs{k}, ...
                100*(max(gn) - min(gn))/mean(gn), 100*(max(ge) - min(ge))/mean(ge), ...
                info.D_target, 1 - max(abs(pe)), el);
        catch ME
            fprintf('%-8s %-20s ERROR %s\n', '', designs{k}, ME.message);
        end
    end
end
set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;
