function fnct2= besselFnct2(p, k, sign, deltT, T0)
%   fnct1= besselFnct1(p, deltT, T0) implements the first function used to solve for bessel roots
%   for equiripple group delay
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

    p2 = p;
    zk = p(k);
    f = @(zi) (zi + zk)/(zi - zk);
    p2(k) = [];
    fnct2 = sign*(zk^2 - 1)^1.5/zk^2 + deltT*prod(arrayfun(f, p2));
    fnct2 = double(fnct2);
    