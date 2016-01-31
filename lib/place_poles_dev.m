%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function Kz_ = place_poles(p,px,ni,wp,ws,as,e_,type)
% Kz_ = place_poles2(p,ni,w,e_,type,px)
% This is a program for placing loss poles.
% This version can handle finite unmoveable poles
% specified in px.

% p: Initial guess at finite loss poles
% px: fixed poles
% ni: number of poles at infinity

% e_ = 0.25; % passband ripple = 1 + e_^2

% type is 'monotonic' for a maximally flat pass-band and 'elliptic' for
% and equi-ripple pass-band

Kz_ = make_init2Kz(p,px,ni,wp,type); % Calculate the initial characteristic eq.

% find the frequencies of the stop-band edges
[wsz As] = trnsfrm_spec(ws,as,wp);
ns = length(ws);

% the smallest wsz is the stop-band edge of the upper stopband. The largest
% wsz is the stopband edge of the lower stopband.

nx=length(px); % number of finite loss poles (including zero)

% check that the fixed poles are different than the moveable poles
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
% add poles at 1, if ni ~= 0
if ni ~= 0
    px_ = sort([px_ ones(1,ni)]);
else
    px_ = sort(px_);
end

if any(px_ < wsz(1)) || any(px_ > wsz(ns))
    error('Some fixed poles have been placed in the transition region');
end

npx_ = length(px_);
[p,np] = get_poles(Kz_,px_); % get the moveable poles from the initial characteristic eq.

if any(p < wsz(1)) || any(p > wsz(ns))
    error('Some moveable poles have been placed in the transition region');
end

% add stopband edges and find range limits
% get rid of fixed poles with multiplicity greater than 1
plim = [wsz(1) px_ wsz(ns)]; % set up the range limits between fixed poles
nplim = length(plim);
if nplim > 0
    indx = [abs(plim(1:nplim-1) - plim(2:nplim)) > 1e-7, 1];
    plim = plim(logical(indx));
end
nplim = length(plim);
nrngs = nplim - 1;

% Construct a structure with an element for each range. Each range should
% have moveable poles
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

if (sum([rng.ni]) ~= np)
    error('the moveable pole range structure has not been initialized properly');
end

if (nrngs == 0)
    Kz_ = make_Kz(p,px_,type); % Calculate the characteristic equation in s'
    return
end

% set up the sensitivity matrix. There is a column for each moveable pole plus
% a column for each range. There is a row for each minima. Each range has ni + 1 minima
s2 = zeros(np + nrngs, nrngs);
k = 1;
for i = 1:nrngs
    for jj = 1:(rng(i).ni + 1)
        s2(k,i) = -1;
        k = k+1;
    end
end

% Set the initial values for the X vector
X = [p.'; ones(nrngs,1)];

% Adapt the pole positions to equalize the stop-band loss minima
for i = 1:1000 % repeat enough times to guarantee success 
    zmin = find_minima(Kz_,ws,as,wp); % find the minima of the stop-band loss

    % Do not consider largest minima when there are fixed poles as the
    % system is over-determined. Different approaches could be considered
    % here.
    Kz2 = Kz_*Kz_';
    nz = length(zmin);

    % Augument with stop-band edge frequencies.
    % Check for special cases where fixed poles are outside all moveable
    % poles and don't augument at those sides.
    if nx > 0
        if ~any(px_ < p(1))
            zmin = [wsz(1) zmin];
        end
        if ~any(px_ > p(np))
            zmin = [zmin wsz(ns)];
        end
    else
        zmin = [wsz(1) zmin wsz(ns)];
    end
    
    % Modified 1/19/2016 as fixed poles where not be handled correctly. Will try and pick zmin above and
    % below moveable poles
    zmin_ = [];
    nzmin = length(zmin);
    puindx = find(p < 1.0);
    pu = p(puindx);
    for k=1:length(pu)
        z1 = zmin(1);
        for m=1:nzmin
            if (zmin(m) < pu(k))
                z1 = zmin(m);
            else
                break;
            end
        end
        zmin_ = [zmin_ z1];
    end
    zmin_ = [zmin_ zmin(m)];

    plindx = find(p > 1.0);
    pl = p(plindx);
    for k=1:length(pl)
        z1 = zmin(1);
        for m=1:nzmin
            if (zmin(m) < pl(k))
                z1 = zmin(m);
            else
                break
            end
        end
        zmin_ = [zmin_ z1];
    end
    zmin_ = [zmin_ zmin(m)];
    zmin = zmin_

    Y = -find_margin(Kz_,ws,as,wp,e_,zmin);
   
    S = [dlogKK_dp(Kz_,px_,zmin) s2]; % Calculate the sensitivity matrix
    % Pmin = 0.01.*diag(ones(1,length(X)));
    % X = (S + Pmin)\(Y); % Calculate the changes in the pole frequencies
    X = (S)\(Y); % Calculate the changes in the pole frequencies
    p = p + 1.0.*X(1:np).'; % Calculate the new pole positions
    % p = sort(p)

    % Check limits and make sure poles don't pass each other
    for k=1:np
        if (k < np) && (p(k) >= p(k+1))
            p(k) = 0.999*p(k+1);
        end
        if (p(k) <= wsz(1))
            p(k) = 1.001*wsz(1);
        end
        if (p(k) >= wsz(ns))
            p(k) = 0.999*wsz(ns);
        end
    end
    if max(abs(X(1:np))) < 1e-8
        disp('Minima Iteration Terminated')
        i
        break
    end
    
    % max(abs(X(1:np)))
    Kz_ = make_Kz(p,px_,type); % Calculate the new characteristic equation in s'
end

zmin = find_minima(Kz_,ws,as,wp); % find the minima of the stop-band loss
if nx > 0
    if ~any(px_ < p(1))
        zmin = [wsz(1) zmin];
    end
    if ~any(px_ > p(np))
        zmin = [zmin wsz(ns)];
    end
else
    zmin = [wsz(1) zmin wsz(ns)];
end
% [zmin2,indx] = sort(-j*z2s(zmin,wp).');
% margin = find_margin(Kz_,ws,as,wp,e_,zmin(indx));
% display('Minima Frequencies');
% zmin2
% display('Stopband Margins');
% 10*margin

a=1; % a place to stop for debugging

