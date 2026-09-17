function zmin = findLossMinima(Hy,wsy,as)
%   zmin = findLossMinima(Hy,wsy,as) finds the stop-band attenuation minima
%   This is a simple program for finding the minima of ln|Hy| in the y
%   domain. The minima are all assumed to be between the loss poles.
%   Loss poles at 0 in z correspond to jw2 in s
%   Loss poles at inf in z correspond to jw1 in s
%   Loss poles at 1 in z correspond to inf in s
%   each loss pole is repeated twice (at least) and normally negative
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

NPTS = 10001;
% REVIEW-LOGSPACE: was log10(logspace(0,100,NPTS)), which is exactly
% linspace(0,100,NPTS) - simplified since they're equivalent (this also
% replaced an original logspace(-2,2,1000) call, i.e. a genuinely
% log-spaced 0.01-100 grid, with today's linear 0-100 grid). If this search
% turns out to need log-spaced points instead, search for REVIEW-LOGSPACE.
w = linspace(0,100,NPTS);
[mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,as,w);
zmin = zrCrss(w,dLdW);
for i=1:4 % Normally 3 iterations is more than adequate
    [mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,as,zmin);
    zmin = zmin - dLdW./d2LdW;
end

a=1; % for debug

