function wy2 = findLossEdges(Hy,avgLsMin,wy1)
%   wy2 = findLossEdges(Hy,avgMrgn,wy1) finds stop-band eges in y where the
%   loss in nepers is equal to avgLsMin
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

lnMrgn = avgLsMin*log(10)/20;
NPTS = 1000;
p = sortImag(Hy.p{1});
w1 = log10(logspace(wy1(1),0.999*imag(p(1)),NPTS)).';
[lgH, phH, gdH, dLdW, dTdW, d2LdW] = AnlzH(Hy, w1);
wy1_ = zrCrss(w1,lgH-lnMrgn);
w2 = log10(logspace(1.0001*imag(p(end)),wy1(2),NPTS).');
[lgH, phH, gdH, dLdW, dTdW, d2LdW] = AnlzH(Hy, w2);
wy2_ = zrCrss(w2,lnMrgn - lgH);
wy2 = [wy1_; wy2_];
for i=1:4 % Normally 3 iterations is more than adequate
    [lgH, phH, gdH, dLdW, dTdW, d2LdW] = AnlzH(Hy, wy2);
    wy2 = wy2 - (lgH - lnMrgn)./dLdW;
end

a=1; % for debug

