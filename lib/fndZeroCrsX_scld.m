function wz = fndZeroCrsX_scld(H, wp)
%   wz = fndZeroCrsX_scld(H, wp) finds the frequencies (rad) of the
%   group-delay extrema of the digital filter H near the passband wp
%   (cycles). It returns the same thing as fndZeroCrs3_scld, but searches
%   in the band-centred transformed variable of z2xc instead of in w.
%
%   z2xc maps the band wp to W in [-1 1] on the imaginary axis, so a grid
%   uniform in W has the same resolution relative to the band however
%   narrow the band is. fndZeroCrs3 uses a fixed w step (2*pi*1e-5), which
%   leaves only about 10 grid points across a band 1e-4 cycles wide and
%   stops finding the extrema.
%
%   Group delays are related by gd_z = J*gd_x with J = (1 + t^2 W^2)/(2t),
%   and W increases with w, so the extrema in w are the zeros of
%   d(J*gd_x)/dW = t*W*gd_x + J*dgd_x/dW. They are found by sign changes
%   on the W grid, refined by linear interpolation as in fndZeroCrs3, and
%   mapped back with w = w0 + 2*atan(t*W). The search window is the same
%   as fndZeroCrs3's (the passband widened by marginMult passband widths
%   each side, doubled while an extremum lies near the edge), and it stops
%   short of Nyquist, so the Nyquist extremum is never returned.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2026  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

    N_GRID = 40001;
    EDGE_PTS = 3;
    MAX_MARGIN_MULT = 64;
    NYQUIST_MARGIN = 1e-3; % keep the window short of w = w0 +- pi
    zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);

    [Hx, t, w0] = z2xc(H, wp);
    % Transmission zeros belong on the unit circle, i.e. on the imaginary
    % axis in x, where they add nothing to the group delay. Rounding in z
    % leaves them off it by roughly eps/t (1e-14 to 1e-11 for bands 1e-3 to
    % 1e-5 cycles wide), which puts spikes in the group delay at those
    % points and gives spurious extrema. In x the axis is Re = 0, which can
    % be set exactly (|z| = 1 generally cannot), so snap them onto it.
    AXIS_TOL = 1e-8;
    [zx, px, kx] = zpkdata(Hx, 'vector');
    onAxis = abs(real(zx)) < AXIS_TOL*max(1, abs(zx));
    zx(onAxis) = j*imag(zx(onAxis));
    Hx = zpk(zx, px, kx);
    % Same search window as fndZeroCrs3: the passband widened by
    % marginMult passband widths on each side, doubled while an extremum
    % lies near the window edge. Here the window is expressed in W, and
    % the grid is uniform in W with a fixed number of points.
    hw = pi*(wp(2) - wp(1)); % passband half-width in rad
    marginMult = 1;
    while true
        halfW = min(hw*(1 + 4*marginMult), pi - NYQUIST_MARGIN);
        Wm = tan(halfW/2)/t;
        W = linspace(-Wm, Wm, N_GRID);
        dT = dTzdW(Hx, W, t);
        indc = zci(dT);
        indc(indc == length(W)) = []; % circshift wrap-around, not a crossing
        nearEdge = any(indc <= EDGE_PTS) | any(indc >= length(W) - EDGE_PTS);
        atLimit = halfW >= pi - NYQUIST_MARGIN;
        if ~nearEdge || atLimit || marginMult >= MAX_MARGIN_MULT
            break
        end
        marginMult = 2*marginMult;
    end
    doubleIndc = find(diff(indc) == 1);
    if ~isempty(doubleIndc)
        indc(doubleIndc+1) = [];
    end
    if isempty(indc)
        wz = [];
        return
    end
    W1 = W(indc).'; % columns, like dT - a row here would expand to a matrix
    W2 = W(indc + 1).';
    d1 = dT(indc);
    d2 = dT(indc + 1);
    Wz = W1 - d1.*(W2 - W1)./(d2 - d1);
    wz = w0 + 2*atan(t*Wz);
    wz = angle(exp(j*wz)); % back into (-pi, pi]
    wz = sort(wz(:)).';
    a = 1;
end

function dT = dTzdW(Hx, W, t)
%   derivative with respect to W of the z-domain group delay J*gd_x
    [~, ~, gdx, ~, dgdx] = AnlzH(Hx, W);
    W = W(:);
    J = (1 + t^2*W.^2)/(2*t);
    dT = t*W.*gdx(:) + J.*dgdx(:);
end
