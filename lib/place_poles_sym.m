function Kz_ = place_poles_sym(p,px,ni,wp,ws,as,e_,type)
%   Kz_ = place_poles_sym(p,px,ni,wp,ws,as,e_,type)
%   Symmetric-filter special case of place_poles.m: for an exactly
%   mirror-symmetric spec (wp(2)==-wp(1), and ws/as palindromic about dc),
%   only the "master" (upper-stopband) movable loss poles are treated as
%   free variables in the Newton iteration; the "mirror" (lower-stopband)
%   poles are derived every iteration as their exact reciprocal in the z
%   domain (see get_poles_sym.m/make_Kz_sym.m/find_minima_sym.m/
%   dlogKK_dp_sym.m), guaranteeing exact rather than approximate symmetry
%   in the result. Same calling contract as place_poles.m.
%
%   For detailed explanation of the underlying (non-symmetric) algorithm see:
%   K. Martin, “Approximation of complex iir bandpass filters without arith-
%   metic symmetry,” IEEE Trans. Circuits and Systems I, vol. 52, pp. 794–
%   803, April 2005.
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

tol_sym = 1e-9;

% Validate the spec is actually symmetric up front, before any iteration.
if abs(wp(2) + wp(1)) > tol_sym*max(abs(wp))
    error('place_poles_sym:asymmetricPassband', ...
        'place_poles_sym requires a mirror-symmetric passband (wp(2) == -wp(1))');
end
[wsSorted, wsIdx] = sort(ws);
asSorted = as(wsIdx);
nws = length(wsSorted);
for i = 1:floor(nws/2)
    if abs(wsSorted(i) + wsSorted(nws+1-i)) > tol_sym*max(abs(wsSorted))
        error('place_poles_sym:asymmetricStopband', ...
            'place_poles_sym requires ws to be symmetric about dc (ws(%d)=%g is not -ws(%d)=%g)', ...
            i, wsSorted(i), nws+1-i, -wsSorted(nws+1-i));
    end
    if abs(asSorted(i) - asSorted(nws+1-i)) > tol_sym*max(abs(asSorted))
        error('place_poles_sym:asymmetricStopbandSpec', ...
            'place_poles_sym requires as to be symmetric about dc (as(%d)=%g ~= as(%d)=%g)', ...
            i, asSorted(i), nws+1-i, asSorted(nws+1-i));
    end
end

Kz_ = make_init2Kz(p,px,ni,wp,type); % Calculate the initial characteristic eq.

[wsz As] = trnsfrm_spec(ws,as,wp);
ns = length(ws);

nx=length(px); % number of finite fixed loss poles (including zero)

% check that the fixed poles are different than the movable poles
for i=1:nx
    if any(p == px(i))
        error('One of the fixed poles has been specified at the same frequency as a moveable pole');
    end
end

% transform fixed poles to z
if nx == 0
    px_ = [];
else
    px_ = s2z(j*px,wp);
end
% add poles at 1 (a pole at infinity transforms to 1 in z domain), if ni ~= 0
if ni ~= 0
    px_ = sort([px_ ones(1,ni)]);
    nx = nx + ni;
else
    px_ = sort(px_);
end

if any(px_ < wsz(1)) || any(px_ > wsz(ns))
    error('Some fixed poles have been placed in the transition region');
end

[p, np2, px_master, nx_master] = get_poles_sym(Kz_, px_); % master-side moveable/fixed poles

if any(p < wsz(1)) || any(p > 1)
    error('Some moveable poles have been placed in the transition region');
end

% add the master-domain edges and find range limits. The master domain is
% always (wsz(1), 1) by construction -- 1 is the exact reciprocal fixed
% point, whether it corresponds to a real fixed pole (ni>0) or is simply
% the master/mirror boundary (ni==0).
plim = unique(sort([wsz(1) px_master 1]));
nplim = length(plim);
if nplim > 0
    indx = [abs(plim(1:nplim-1) - plim(2:nplim)) > 1e-7, 1];
    plim = plim(logical(indx));
end
nplim = length(plim);
nrngs = nplim - 1;

% Construct a structure with an element for each master-side range.
k=0;
for i = 1:nrngs
    rlim1 = plim(i); % the lower frequency limit
    rlim2 = plim(i+1); % the upper frequency limit
    indcs = find((p > plim(i)) & (p < plim(i+1))); % find the indcs of the moveable poles
    nindcs = length(indcs); % the number of moveable poles in the range
    if nindcs ~= 0 % store the indices of the moveable poles in the range
        k = k+1;
        rng(k).ni = nindcs;
        rng(k).i1 = indcs(1);
        rng(k).i2 = indcs(nindcs);
        rng(k).lim1 = rlim1;
        rng(k).lim2 = rlim2;
    end
end
nrngs = k;

if (sum([rng.ni]) ~= np2)
    error('the moveable pole range structure has not been initialized properly');
end

if (nrngs == 0)
    Kz_ = make_Kz_sym(p,px_,type); % Calculate the characteristic equation in s'
    return
end

% set up the sensitivity matrix. There is a column for each master
% moveable pole plus a column for each range. There is a row for each
% (master-side) minima. Each range has ni + 1 minima
s2 = zeros(np2 + nrngs, nrngs);
k = 1;
for i = 1:nrngs
    for jj = 1:(rng(i).ni + 1)
        s2(k,i) = -1;
        k = k+1;
    end
end

% fixed markers used by prune_zmin to decide which minima are between two
% adjacent fixed poles (and so not adjustable); "1" only counts as a real
% fixed marker here if it corresponds to an actual fixed pole (ni>0) --
% otherwise it is just the master/mirror bookkeeping boundary.
if ni > 0
    px_master_prune = sort([px_master 1]);
else
    px_master_prune = px_master;
end

% Set the initial values for the X vector
X = [p.'; ones(nrngs,1)];

% Adapt the pole positions to equalize the stop-band loss minima
for i = 1:2000 % repeat enough times to guarantee success
    zmin = find_minima_sym(Kz_,ws,as,wp);
    zmin = prune_zmin(p, px_master_prune, zmin); % get rid of mins between fixed poles

    % Augment with the (left) stop-band edge frequency. The right edge of
    % the master domain is always 1, not the far (mirror-side) stopband
    % edge wsz(ns) -- that edge belongs to the mirror side and is never
    % represented directly in the reduced system.
    if nx_master > 0
        if ~any(px_master < p(1))
            zmin = [wsz(1) zmin];
        end
    else
        zmin = [wsz(1) zmin];
    end

    Y = -find_margin(Kz_,ws,as,wp,e_,zmin);

    S = [dlogKK_dp_sym(Kz_,px_,p,zmin) s2]; % Calculate the reduced sensitivity matrix
    Pmin = 1e-6.*diag(ones(1,length(X)));
    X = (S + Pmin)\(Y); % Calculate the changes in the pole frequencies
    p = p + 1.0.*X(1:np2).'; % Calculate the new pole positions

    % Check limits and make sure poles don't pass each other or exceed the
    % master domain's right-hand boundary (1, or a fixed pole closer than
    % that) -- this bound was implicit before via the far stopband edge,
    % but needs to be explicit here since nothing else stops p(np2) from
    % drifting into the mirror region during a large Newton step.
    for k=1:np2
        if (k < np2) && (p(k) >= p(k+1))
            p(k) = 0.999*p(k+1);
        end
        if (p(k) <= wsz(1))
            p(k) = 1.001*wsz(1);
        end
    end
    rightBound = rng(nrngs).lim2;
    if p(np2) >= rightBound
        p(np2) = 0.999*rightBound;
    end

    if max(abs(X(1:np2))) < 1e-7
        fprintf('Symmetric-mode minima iteration terminated in %d iters, error: %d\n', ...
            i, max(abs(X(1:np2))));
        break
    end

    Kz_ = make_Kz_sym(p,px_,type); % Calculate the new characteristic equation in s'
end

a=1; % a place to stop for debugging
