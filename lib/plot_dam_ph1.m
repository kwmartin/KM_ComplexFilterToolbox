% --------------------------- plot_dam_ph1.m ---------------------------
function [ax1, ax2] = plot_dam_ph1(H, wp, ws, colour) %#ok<INUSD>
%   PLOT_DAM_PH1(H,wp,ws,colour) is plot_dam_ph with magnitude and phase
%   combined on one set of axes:
%     Magnitude: red,  x-axis top,    y-axis left
%     Phase:     blue, x-axis bottom, y-axis right
%   The colour argument is kept only so the call signature matches the
%   original; the two colours are fixed.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2018  Kenneth Martin   (GPL v3 or later; see original header)

[zd, pd, kd] = zpkdata(H);
b = poly(zd{1});
a = poly(pd{1});
A = db(kd.*freqz(b,a,2*pi*[wp ws]));  %#ok<NASGU>  (kept from the original)
w = -0.5:1e-4:0.5;
s = 2*pi*w;
x2n = @(x) int16(length(w)*(x + 0.5));
h   = kd.*freqz(b,a,s);
dbH = db(h);
phH = unwrap(angle(h))*(180/pi);

n1 = x2n(wp(1));
n2 = x2n(wp(2));
wdiff = wp(2) - wp(1);
xr = [wp(1) - 0.05*wdiff, wp(2) + 0.05*wdiff];

% ---- curve 1: magnitude (top x, left y) ----
mag.x      = s./(2*pi);
mag.y      = dbH;
mag.color  = 'r';
mag.xlim   = xr;
mag.ylim   = [min(dbH(n1:n2)) - 0.1, max(dbH(n1:n2)) + 0.1];
mag.xlabel = 'Frequency';
mag.ylabel = 'Magnitude (dB)';
mag.name   = 'Magnitude';

% ---- curve 2: phase (bottom x, right y) ----
ph.x      = s./(2*pi);
ph.y      = phH;
ph.color  = 'b';
ph.xlim   = xr;                 % can differ from mag.xlim if needed
ph.ylim   = [min(phH(n1:n2)) - 45, max(phH(n1:n2)) + 45];
ph.xlabel = 'Frequency';
ph.ylabel = 'Phase (Degrees)';
ph.name   = 'Phase';

figure('Position', [800 100 600 600]);
[ax1, ax2] = plotTwo(mag, ph, 'Magnitude Gain and Phase');
end

% ------------------------------ Usage --------------------------------
% Save each function as its own file (plotTwo.m, plot_dam_ph1.m), or keep
% setDefaults as a local function at the bottom of plotTwo.m.
%   [ax1, ax2] = plot_dam_ph1(H, wp, ws, 'r');
% Later adjustments, e.g.:
%   ylim(ax2, [-180 180]);   xlim(ax1, [0.1 0.2]);
% Zoom and pan only act on the top axes (ax2). To make both x-axes move
% together, add:  linkaxes([ax1 ax2], 'x')
% Needs R2016a or later for line(ax,...) and the dot-notation Position.
