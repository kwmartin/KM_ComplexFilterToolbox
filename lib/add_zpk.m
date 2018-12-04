function H3= add_zpk(H1, H2)
% ADD_ZPK(H1, H2) transforms two zpk systems in parallel to a single system
% The routine is a bit old (11/2018) and can probably be improved. It uses
% the matlab minimizer fzero()
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

[z1, p1, k1] = zpkdata(H1, 'v');
[z2, p2, k2] = zpkdata(H2, 'v');

mxOrd1 = mxOrdr(H1);
mxOrd2 = mxOrdr(H2);
if (mxOrd1 >= mxOrd2)
  mx_Ordr = mxOrd1;
else
  mx_Ordr = mxOrd2;
end

p3 = [p1; p2];
[sorted, idx] = sort(-imag(p3));
p3 = p3(idx);
proto = simpl(tf(H1) + tf(H2));
%assert(mx_Ordr >= mxOrdr(proto), 'Failed Assert Approximate Transfer Function has Correct Order')

[zPrx, pPrx, kPrx] = zpkdata(proto, 'v');

% Accurate TF is (k1z1p2 + k2 z2p1)/(p1p2)
% Denom is found simply by concatenating roots
% Numerator is found by solving for roots of (k1z1p2 + k2 z2p1) using
% fzero with roots of proto as starting points
% Note: according to Matlab documentation fzero requires real args
% and must produce real results for optimized function

za = [z1; p2]; zb = [z2; p1];
zpka = zpk(za, [], k1); zpkb = zpk(zb, [], k2);
evlNum = @(zpka, zpkb, wz) (evalfr(zpka, wz*j) + evalfr(zpkb, wz*j));
%evlNum = @(zpka, zpkb, wz) (evalfr(zpka, wz) + evalfr(zpkb, wz));
evlFun = @(wz) real(evlNum(zpka, zpkb, wz)) + imag(evlNum(zpka, zpkb, wz));

z_ = [];
interval = 1e-5*(1 + j);
%interval = 1e-5*(1 + j);
for i=1:length(zPrx)
    w0 = zPrx(i)*(-j);
    %w0 = zPrx(i);
    x0 = [(w0 - interval) (w0 + interval)];
    wz = fzero(evlFun, w0, optimset('TolX', 1e-10, 'TolFun', 1e-12));
    % wz = fzero(evlFun, x0, optimset('Display','iter','TolX', 1e-10, 'TolFun', 1e-10));
    z_(i) = j*wz;
end
z_ = z_.';
[sorted, idx] = sort(-imag(z_));
z_ = z_(idx);
H3 = zpk(z_, p3, kPrx);
H3 = minreal(H3, 1e-6);