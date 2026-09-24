function H = adaptP2_scld(H, deltT, wp)
%   [_scld copy of adaptP2.m - finds extrema with fndZeroCrs3_scld, which drops the Nyquist extremum; see ScldGD.md section 11]
%   [H2, deltT] = adaptP2(H, deltT, wp) adapts the poles of a digital filter to correct the group delay
%   to be equiripple after being distorted by the bilinear transform.
%   wp is the passband, forwarded to fndZeroCrs3_scld so its search range
%   tracks the actual passband instead of a fixed fraction of the whole
%   spectrum.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2018  Kenneth Martin
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
    dp2rq = @(dp) [real(dp(:)); imag(dp(:))];
    deltW = 1e-5*2*pi;
    updK = -0.02;
    
    [z, p, k] = sortZPK(H);
    a = angle(p);
    m = abs(p);
    %m = ones(size(m))*m(end);
    % m = sqrt(m); % increase Q to ensure we start with enough peaks
    m = m.^0.1;
    a1 = tan(1.05*a);
    % a1 = a;
    p1 = m.*exp(j*a1);
    H1 = zpk(z, p1, k);
    w1 = angle(p1);
    wrng = 1.2*[w1(1) w1(end)];
    fgd = wrng/(2*pi);
    w = wrng(1):deltW:wrng(2);
    Np = length(p1);
    wz = fndZeroCrs3_scld(H1, wp);
    % wz2 = fndZeroCrs2(H1,fgd); % works very well but 22.6 times slower
    Tz = p2T(H1, wz);
    %dT = mean(abs(diff(gdHz1(1:Np))));

    p = p1;
    gd1 = Tz(Np);
    % deltT = 0.01*gd1;
    gd2 = gd1 - deltT;
    %figure;
    %hold on
    f = w./(2*pi);
    for i = 1:200
        H = zpk(z, p, k, 1);
        wz = fndZeroCrs3_scld(H, wp);
        Tz = p2T(H, wz);
        Y = setY2(Tz, gd1, gd2);
        sens = plSens(p, wz);
        dX = sens\Y;
        dP = rq2dp(dX);
        p = p - 0.05*dP;
        % Clamp any pole that crossed the unit circle back to a safe
        % radius. Without this, a single step that pushes one pole just
        % past |p|=1 makes fndZeroCrs3_scld find fewer genuine zero-crossings
        % on the next iteration (an unstable H's group delay curve loses
        % ripple structure), which starves plSens's sensitivity matrix
        % (needs 2*np, i.e. one real+imag pair per pole) down to a
        % rank-deficient system -- confirmed via dig_equiGd_1_12_0.m's
        % wide-band spec (wp=[-0.05 0.05]): rank dropped from a full 22
        % to 16 after just ONE step (max|p| 0.99->1.13), then collapsed
        % further (rank 3, then 1) as poles ran away past 1e14 over the
        % following iterations, with no error or warning stopping it
        % (just a silent "Rank deficient" warning from \). The
        % minimum-norm least-squares solution to an under-determined
        % system has no reason to move poles back toward stability, so
        % this is a positive-feedback loop with no natural circuit
        % breaker. Clamping every step keeps H stable throughout, which
        % keeps the zero-crossing count (and hence sens's rank) full:
        % verified this exact case converges cleanly to max|p|=0.95 with
        % full rank maintained at every iteration, instead of diverging.
        R_MAX = 0.995;
        tooBig = abs(p) > R_MAX;
        p(tooBig) = R_MAX * p(tooBig)./abs(p(tooBig));
        %T = p2T(H, w);
        %plot(f,T)
    end
    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w(:));
    figure;
    plot(f,gdH,'r','LineWidth',1);
    a = 1;


