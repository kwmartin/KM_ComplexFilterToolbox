% Non-interactive comparison of eqlzrD_peakNewtonStep (clusters as
% (theta, r) in z, r clamped to [0.3, 0.995]) with eqlzrD_peakNewtonStepX_scld
% (clusters as (Wp, sigma) in the band-centred transformed variable, sigma
% clamped in band units), on the dsgnEqlzrD_peakNewton_manual setup with its
% passband shrunk by factors of 10 (see ScldGD.md section 9).
%
% Both run the manual's two phases: angle-only (step 0.2, up to 100 steps,
% stop when the spread changes by < 1e-4 of the anchor), then joint (step
% 0.1, up to 50 steps, keep the best, patience 5). Start: 5 clusters of 5
% stages at 10/30/50/70/90% of the passband with r = 0.925. The x version
% starts from the same poles mapped exactly at the 0.05-cycle width, and
% from the same (Wp, sigma) in band units at every width; the z version keeps
% r = 0.925. Also checks the x Jacobian against finite differences.
% Takes a few minutes.

figVis = get(0, 'DefaultFigureVisible'); warnState = warning;
set(0, 'DefaultFigureVisible', 'off'); warning('off', 'all');

p = [-0.35 -0.25 -0.1 -0.08 0.25 0.35];
ni = 1; px = []; as = [70 50 50 70]; Ap = 0.05;
fracs = linspace(0.10, 0.90, 5);
clusterCount = 5*ones(1,5);
R0 = 0.925;
BW_REF = 0.05;
% cluster start in band units: the z start mapped exactly at the reference
% width (w0 = 0 there, since only the offset from the band centre matters)
tRef = tan(pi*BW_REF/2);
thRef = 2*pi*(fracs - 0.5)*BW_REF;
aRef = R0*exp(1j*thRef);
xRef = ((aRef - 1)./(aRef + 1))/tRef;
sigma0 = -real(xRef);
Wp0 = imag(xRef);

fprintf('%-8s %-12s %10s %10s %12s %12s %8s\n', 'width', 'version', ...
    'p2p nom %', 'p2p exp %', 'spread/anch', '1-max|pole|', 'clamped');
for s = [1 1e-1 1e-2 1e-3]
    wp = [-0.025 0.025]*s;
    ws = [-0.49 -0.049*s 0.049*s 0.49];
    [p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
    [~, cscd] = evalc('dsgnCscdFltr(p_, px_, ni, wp_, ws_, as, Ap, ''elliptic'')');
    H = cscd.getSystem();
    close all;
    % the design path turns warnings back on; silence the clamp messages
    % (clamping is reported in the table instead)
    warning('off', 'eqlzrD_peakNewtonStep:rClamped');
    warning('off', 'eqlzrD_peakNewtonStepX_scld:sigmaClamped');
    [~, stats] = estAllPassOrder(H, wp_);
    gdH0 = stats.gdH(:);
    anchor = mean(gdH0(islocalmax(gdH0, 'MinProminence', 5)));
    w0 = pi*sum(wp_);
    t = tan(pi*diff(wp_)/2);

    % z version: (theta, r)
    th = 2*pi*(wp_(1) + fracs*diff(wp_));
    stepZ = @(a, b, st, fr) eqlzrD_peakNewtonStep(H, a, b, clusterCount, anchor, wp_, st, [], fr);
    toZ = @(a, b) repelem(b, clusterCount).*exp(1j*repelem(a, clusterCount));
    [a, b, sp, cl] = runPhases(stepZ, th, R0*ones(1,5), anchor);
    report(s*BW_REF, 'z (theta,r)', H, toZ(a, b), wp_, sp/anchor, cl);

    % x version: (Wp, sigma)
    stepX = @(a, b, st, fr) eqlzrD_peakNewtonStepX_scld(H, a, b, clusterCount, anchor, wp_, st, [], fr);
    toX = @(a, b) exp(1j*w0)*(1 + t*(-repelem(b, clusterCount) + 1j*repelem(a, clusterCount))) ...
        ./(1 - t*(-repelem(b, clusterCount) + 1j*repelem(a, clusterCount)));
    if s == 1
        checkJacobian(H, Wp0, sigma0, clusterCount, anchor, wp_);
    end
    [a, b, sp, cl] = runPhases(stepX, Wp0, sigma0, anchor);
    report(s*BW_REF, 'x (Wp,sigma)', H, toX(a, b), wp_, sp/anchor, cl);
end
set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;

function [a, b, bestSpread, clamped] = runPhases(stepFn, a, b, anchor)
%   the two phases of dsgnEqlzrD_peakNewton_manual, non-interactive
    spreadPrev = Inf;
    clamped = false;
    for iter = 1:100
        [a, b, info] = stepFn(a, b, 0.2, false);
        if abs(info.spreadBefore - spreadPrev) < 1e-4*anchor
            break
        end
        spreadPrev = info.spreadBefore;
    end
    bestSpread = info.spreadBefore; bestA = a; bestB = b; noImprove = 0;
    for iter = 1:50
        [a, b, info] = stepFn(a, b, 0.1, true);
        clamped = clamped || info.rClamped;
        if info.spreadBefore < bestSpread
            bestSpread = info.spreadBefore; bestA = a; bestB = b; noImprove = 0;
        else
            noImprove = noImprove + 1;
            if noImprove >= 5, break, end
        end
    end
    a = bestA; b = bestB;
end

function report(width, label, H, poles, wp_, spreadRel, clamped)
    Heq = eqlzrDClass(poles(:), 1).applyTo(H);
    fn = linspace(wp_(1), wp_(2), 4001);
    fe = linspace(wp_(1) - 0.1*diff(wp_), wp_(2) + 0.1*diff(wp_), 4001);
    [~, ~, gn] = AnlzDH(Heq, 2*pi*fn);
    [~, ~, ge] = AnlzDH(Heq, 2*pi*fe);
    fprintf('%-8.0e %-12s %10.2f %10.2f %12.4f %12.3g %8d\n', width, label, ...
        100*(max(gn) - min(gn))/mean(gn), 100*(max(ge) - min(ge))/mean(ge), ...
        spreadRel, 1 - max(abs(poles)), clamped);
end

function checkJacobian(H, Wp, sg, cnt, anchor, wp_)
%   compares eqlzrD_peakNewtonStepX_scld's closed-form Jacobian with a
%   central finite difference of the group delay at the same extrema
    [~, ~, info] = eqlzrD_peakNewtonStepX_scld(H, Wp, sg, cnt, anchor, wp_, 0, [], true);
    w0 = pi*sum(wp_); t = tan(pi*diff(wp_)/2);
    gdAt = @(Wp_, sg_) gdEq(H, Wp_, sg_, cnt, w0, t, info.f_peaks);
    h = 1e-6;
    n = numel(Wp);
    Jfd = zeros(numel(info.f_peaks), 2*n);
    for i = 1:n
        e = zeros(1, n); e(i) = h;
        Jfd(:, i) = (gdAt(Wp + e, sg) - gdAt(Wp - e, sg))/(2*h);
        Jfd(:, n+i) = (gdAt(Wp, sg + e) - gdAt(Wp, sg - e))/(2*h);
    end
    sgnGain = sign(info.gd_peaks(:) - anchor).*info.gainAtPeaks(:);
    Jfd = Jfd.*sgnGain;
    fprintf('x Jacobian vs finite difference: max relative error %.2g\n', ...
        max(abs(info.J(:) - Jfd(:)))/max(abs(Jfd(:))));
end

function g = gdEq(H, Wp, sg, cnt, w0, t, f)
    x = -repelem(sg, cnt) + 1j*repelem(Wp, cnt);
    Heq = eqlzrDClass((exp(1j*w0)*(1 + t*x)./(1 - t*x)).', 1).applyTo(H);
    [~, ~, g] = AnlzDH(Heq, 2*pi*f(:));
end
