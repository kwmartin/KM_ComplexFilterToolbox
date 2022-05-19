function [mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,as,w)
%   [mrgn, phH, gdH, dLdW, dTdW, d2LdW] = getMarginLP(Hy,wsy,as,w) finds stop-band margins
%   find_the differences between the stopband loss
%   and the interpolated specs at the frequencies specified by the vector w. As
%   should be in dB. The various derivatives are also return; for these,
%   the specifications are ignored.
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

% margin's scale is indeterminate
w = w(:); % poles are rows, freqs are column

% convert specs to logs and interpolate
wsy(wsy == Inf) = 1e6;
aIntrp = log(10)*(interp1(wsy, as, w))./20;
% The following analysis takes less 1ms for 1000 frequency points
[lgH, phH, gdH, dLdW, dTdW, d2LdW] = AnlzH(Hy, w);
mrgn = lgH - aIntrp;
a = 1;