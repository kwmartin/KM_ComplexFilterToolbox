function Hy = place_polesdLP(e,p,px,ni,wt,ws,as,e_,type)
%   Hy = place_polesdLP(e,p,ni,w,e_,type,px)
%   This is a program for placing loss poles to equalize stop-band
%   minima. The specifications need not be constant or symmetric
%   This version can handle finite unmoveable poles
%   specified in px.
%
%   e: the zeros which are not moved (also equal to the natural modes)
%   p: Initial guess at finite loss poles
%   px: fixed poles
%   ni: number of poles at infinity
%
%   e_ = 0.25; % passband magnitude squared ripple = 1 + e_^2
%
%   type is 'monotonic' for a maximally flat pass-band and 'elliptic' for
%   an equiripple pass-band
%
%   For detailed explanation see:
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

%Transform used for discrete time to continous-time with stop-band at jw for 0 < w < Inf
z2y = @(z,wi)(j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
w2x = @(w, wi) ((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1)));

% Hy = make_initHyLP(e,p,px,ni,wt,type); % Calculate the initial H in y domain
% find the stop-band specification frequencies in the y domain
wsy = w2x(2*pi*ws,wt);
[wsy As] = trnsfrm_specdLP(ws,as,wt);
ns = length(wsy);

% Note that in y all poles are between 0 and Inf and are on jw axis

nx=length(px); % number of finite loss poles (including zero)

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
    px_ = z2y(j*px,wt);
end
% add poles at 1 (a pole at infinity transforms to 1 in z domain), if ni ~= 0
if ni ~= 0
    px_ = sort([px_ j*ones(1,ni)]);
    nx = nx + ni;
else
    px_ = sort(px_);
end

if any(px_ < wsy(1)) || any(px_ > wsy(ns))
    error('Some fixed poles have been placed in the transition region');
end

% Transform moveable poles
npx_ = length(px_);
%[p,np] = get_poles(Kz_,px_); % get the moveable poles from the initial characteristic eq.
np = length(p);
py = j*sort(w2x(2*pi*p,wt)); % all loss poles are positive imaginary
if any(py < 0)
    error('Some moveable poles have been placed in the transition region');
end

% add stopband edges and find range limits
% get rid of fixed poles with multiplicity greater than 1
plim = [0 px_ j*Inf]; % set up the range limits between fixed poles
nplim = length(plim);
if nplim > 0
    indx = [abs(plim(1:nplim-1) - plim(2:nplim)) > 1e-7, 1];
    plim = plim(logical(indx));
end
nplim = length(plim);
plim = j*imag(plim); % all transformed loss poles should be imaginary
nrngs = nplim - 1;

% Construct a structure with an element for each range. Each range should
% have moveable poles
k=0;
for i = 1:nrngs
    rlim1 = plim(i); % the lower frequency limit
    rlim2 = plim(i+1); % the upper frequency limit
    indcs = find((imag(py) > imag(plim(i))) & (imag(py) < imag(plim(i+1)))); % find the indcs of the moveable poles
    nindcs = length(indcs); % the number of moveable poles in the range
    if nindcs ~= 0 % store the indices of the moveable poles in the range
        k = k+1;
        rng(k).ni = nindcs;
        rng(k).i1 = indcs(1);
        rng(k).i2 = indcs(nindcs);
        rng(k).lim1 = rlim1;
        rng(k).lim2 = rlim2;
        rng(k).zmin = 0.5*(rlim2 - rlim1);
    end
end
nrngs = k;
if (nrngs == 0)
    return
end

if (sum([rng.ni]) ~= np)
    error('the moveable pole range structure has not been initialized properly');
end

pls = sortImag([px_ py]);
Hy = zpk(e, pls, 1);

% set up the sensitivity matrix. There is a column for each moveable pole plus
% a column for each range. There is a row for each minima. Each range has ni + 1 minima
% each range has its own unknown margin which multiplies the s2 columns
% (one column per range).
s2 = zeros(np + nrngs, nrngs);
k = 1;
for i = 1:nrngs
    for jj = 1:(rng(i).ni + 1)
        s2(k,i) = -1;
        k = k+1;
    end
end

% For exmpl9.m, this worked once I commented out the next line, KM
% if length(s2) == 2 s2 = [s2; -1]; end % special case, KM: 7/3/2018 I don't understand this way after the fact

% Set the initial values for the X vector
py = imag(py);
px_ = imag(px_);
X = [py(:); ones(nrngs,1)];

% Adapt the pole positions to equalize the stop-band loss minima
% Note we have made the loss pole positions real
for i = 1:2000 % repeat enough times to guarantee success 
    zmin = findLossMinima(Hy,wsy,as,wt); % find the minima of the stop-band loss
    zmino = prune_zmin(p, px_, zmin); % get rid of mins between fixed poles
    zmin = zmino;

    % Do not consider largest minima when there are fixed poles as the
    % system is over-determined. Different approaches could be considered
    % here.
    nz = length(zmin);

    % Augument with stop-band edge frequencies.
    % Check for special cases where fixed poles are outside all moveable
    % poles and don't augument at those sides.
    if nx > 0
        if ~any(px_ < py(1))
            zmin = [wsy(1) zmin];
        end
        if ~any(px_ > py(np))
            zmin = [zmin wsy(ns)];
        end
    else
        zmin = [wsy(1) zmin wsy(ns)];
    end
    % Most functions can't handle Inf which corresponds to wp(2)
    zmin(zmin == Inf) = 1e6; % The might be too small for very high order filters
    [mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,as,zmin,wt);
    Y = -mrgn;
    % Y = -find_margind(Kz_,ws,as,wt,e_,zmin);
    
    S = [dHy_dp(Hy,j*px_,zmin) s2];
    Pmin = 1e-6.*diag(ones(1,length(X)));
    X = (S + Pmin)\(Y); % Calculate the changes in the pole frequencies
    % X = (S)\(Y); % Calculate the changes in the pole frequencies
    py = py + 1.0.*X(1:np).'; % Calculate the new pole positions
    % p = sort(p)

    % Check limits and make sure poles don't pass each other
    for k=1:np
        if (k < np) && (py(k) >= py(k+1))
            py(k) = 0.999*p(k+1);
        end
        if (py(k) <= wsy(1))
            py(k) = j*1.001*wsy(1);
        end
        if (py(k) >= wsy(ns))
            py(k) = j*0.999*wsy(ns);
        end
    end
    if max(abs(X(1:np))) < 1e-7
        fprintf('Minima Iteration Terminated in %d iters, error: %d\n', ...
            i, max(abs(X(1:np))));
        break
    end
    
    % max(abs(X(1:np)))
    Hy = zpk(e,j*sort([py px_]),1);
end

zmin = findLossMinima(Hy,wsy,as,wt); % find the minima of the stop-band loss
if nx > 0
    if ~any(px_ < py(1))
        zmin = [wsy(1) zmin];
    end
    if ~any(px_ > py(np))
        zmin = [zmin wsy(ns)];
    end
else
    zmin = [wsy(1) zmin wsy(ns)];
end
% [zmin2,indx] = sort(-j*z2s(zmin,wt).');
% margin = find_margin(Kz_,ws,as,wt,e_,zmin(indx));
% display('Minima Frequencies');
% zmin2
% display('Stopband Margins');
% 10*margin

a=1; % a place to stop for debugging

