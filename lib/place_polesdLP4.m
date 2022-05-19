function Hz = place_polesdLP4(H,wp)
%   Hy = place_polesdLP4(e,p,ni,w,e_,type,px)
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
w2x = @(w, wi) -((2.*tan(w./2) - wi(2))./(2.*tan(w./2) - wi(1)));
y2z = @(y,wi)((2*j - wi(2) - y.*(2 + j*wi(1)))./(2*j + wi(2) - y.*(2 - j*wi(1))));
x2w = @(x,wi)(2.*atan((wi(2)*ones(size(x)) - wi(1).*x)./(2*ones(size(x)) - 2.*x)));

% We first transform to y ensuring we include the stop-band but not the
% pass-band
dWp = 0.2*(wp(2) - wp(1))/2;
fsb1 = [wp(1)- dWp, wp(2) + dWp];
Hy1 =  z2ySbTrnsf1(H,fsb1);
Hy1 = 1/Hy1;
% Now we find the edge frequencies have the same loss as the average of the
% stop-band loss minima
wt1 = 2*pi*fsb1;
wsy = [0, 0.9999, 1.00001, 1e6];
ns = 4;
asy = 20*ones(size(wsy));
zmin = findLossMinima(Hy1,wsy,asy);
lossMin = db(rsps(Hy1,j*zmin));
lssMin = min(lossMin);
py = sortImag(Hy1.p{1});
wy1 = imag([0.9*py(1) 1.1*py(end)]);
wy2 = findLossEdges(Hy1,lssMin,wy1);
% Now transform these back to z and use them as the basis
% for transforming back to y. This new transform will have band edge losses
% equal to the average of the loss minima
fsb2 = sort(x2w(wy2, 2*tan(wt1/2)))/(2*pi);
Hy2 =  z2ySbTrnsf1(H,fsb2);
% just experimental; the previous line should be used
% dWp = 0.5*(wp(2) - wp(1))/2;
% fsb1 = [wp(1)- dWp, wp(2) + dWp];
% Hy2 =  z2ySbTrnsf1(H,fsb1); 
Hy2 = 1/Hy2;

a=1;

[ey, py_, ky] = sortZPK(Hy2);
py_ = py_.'; % convert to column
py_ = imag(py_); % convert to real for adaptation; we'll convert back later
py = py_(abs(py_ - 1) > 1e-7);
ni = length(py_(abs(py_ - 1) <= 1e-7));
Hy = Hy2;
np = length(py);

% set up the sensitivity matrix.
s2 = -1*ones(np+1,1);

X = [py(:); 0];

% Adapt the pole positions to equalize the stop-band loss minima
% Note we have made the loss pole positions real
for i = 1:2000 % repeat enough times to guarantee success 
    zmin = findLossMinima(Hy,wsy,asy); % find the minima of the stop-band loss
    % Augument with stop-band edge frequencies.
    zmin = [wsy(1); zmin; wsy(ns)];
    % Most functions can't handle Inf which corresponds to wp(2)
    zmin(zmin == Inf) = 1e6; % The might be too small for very high order filters

    [mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,asy,zmin);
    [zmnSrt indxs] = sort(mrgn);
    if length(indxs) > np + 1
        zmin = zmin(indxs(1:np+1));
        mrgn = mrgn(indxs(1:np+1));
    end
    % system is over-determined. Different approaches could be considered
    % here.
    nz = length(zmin);
    
    Y = -mrgn;
    
    S = [dHy_dp2b(Hy,zmin) s2];
    Pmin = 1e-6.*diag(ones(1,length(X)));
    X = (S + Pmin)\(Y); % Calculate the changes in the pole frequencies
    % X = (S)\(Y); % Calculate the changes in the pole frequencies
    py = py + 0.5.*X(1:np).'; % Calculate the new pole positions
    % p = sort(p)

    % Check limits and make sure poles don't pass each other
    for k=1:np
        if (k < np) && (py(k) >= py(k+1))
            py(k) = 0.999*py(k+1);
        end
        if (py(k) <= wsy(1))
            py(k) = 1.001*wsy(1);
        end
        if (py(k) >= wsy(ns))
            py(k) = 0.999*wsy(ns);
        end
    end
    if (max(abs(X(1:np))) < 1e-7) | (max(abs(diff(mrgn))) < 1e-4)
        fprintf('Minima Iteration Terminated in %d iters, error: %d\n', ...
            i, max(abs(diff(mrgn))));
        break
    end
    
    % max(abs(X(1:np)))
    py_ = [py ones(1,ni)];
    py_ = sort(py_);
    
    Hy = zpk(ey,j*py_,ky);
end

zmin = findLossMinima(Hy,wsy,asy); % find the minima of the stop-band loss
zmin = [wsy(1); zmin; wsy(ns)];
zmin(zmin == Inf) = 1e6; % The might be too small for very high order filters
[mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,asy,zmin);
% display('Minima Frequencies');
% zmin
% display('Stopband Margins');
% 20*mrgn./log(10)
Hy = 1/Hy; % return in forward gain form, not in loss form
Hz = y2zSbTrnsf1(Hy,fsb2);
Hz.k = Hz.k/(abs(rspsd(Hz,j*(wp(2) + wp(1))*pi)));
a=1; % a place to stop for debugging

