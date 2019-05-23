function Rts = besselRts(X, deltT)
%   Rts = besselRts(X, deltT) returns the n+1 equation values that need to be zero
%   for a Bessel-Thomson filter having equi-ripple group delay in the passband
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

    n = length(X) - 1;
    p = X(1:end-1);
    T0 = X(end);
    f1 = @(zi) (1 + zi)/(-1 + zi);
    f2 = @(zi) (1 - zi)/(-1 - zi);
    Rts(1) = 0.5*(prod(arrayfun(f1, p)) + prod(arrayfun(f2, p))) - 2*T0/deltT;

    for k=1:n
        p2 = p;
        zk = p(k);
        p2(k) = [];

        f3 = @(zi) (zi + zk)/(zi - zk);
        Rts(k+1) = -((zk^2 - 1)^1.5)/(zk^2) + deltT*prod(arrayfun(f3, p2));
    end
    a=1;