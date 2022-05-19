function wz = fndZeroCrs3(H)
%   indc = fndZeroCrs3(H) finds the zero-crossings of the derivative function used in
%   finding peaks for adapting the poles to get equiripple group delay of a digital filter
%   Inputs are the frequency vector (in Hz), the derivatives at those frequencies, and the
%   pole positions; the angles of the poles are used to determine the starting and endpoints
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

    [z, p, k] = sortZPK(H);
    deltW = 1e-5*2*pi;
    wrng = 2*pi*[-0.45 0.45];
    w = wrng(1):deltW:wrng(2);
    zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);

    [lgH, phH, gdH, dLdW, dTdW] = AnlzDH(H, w);
    indc = zci(dTdW);
    doubleIndc = find(diff(indc) == 1);
    % If dTdW has a zero value, it will give two values in indc; delete the
    % second one
    if ~isempty(doubleIndc)
        indc(doubleIndc+1) = [];
    end
    
    if indc(end) == length(w) indc(end) = []; end

    %dTdW2 = gltchRmv(dTdW);
    % dTdW2 = medfilt1(dTdW);
    f = w./(2*pi);
    % indc = fndZeroInd(w,dTdW2,p);
    w2 = w(indc + 1);
    w1 = w(indc);
    dd2 = dTdW(indc + 1);
    dd1 = dTdW(indc);
    wz = w1 - dd1.*(w2 - w1)./(dd2 - dd1);

    a=1;