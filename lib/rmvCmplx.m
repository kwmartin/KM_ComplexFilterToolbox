function [elem1, elem2, Y2, Yrem] = rmvCmplx(Y1, wp)
%   [elem1, elem2, Y2, Yrem] = rmvCmplx(Y1, wp) removes a loss pole wp
%   using a partial removal of a complex impedance
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
    warning('off', 'Control:ltiobject:TFComplex');
    %tol = 10*sqrt(eps);
    tol = 2e-5;
    fail = false;
    ord = fndOrdr(Y1);
    if ord(1) < ord(2)
        fail = true
    end
    X = imag(evalfr(Y1, wp))*j;
    elem1 = ladderElem(0, 0, 0, X, 'SHX');
    rmvX = tf([X], [1]);
    YIN2 = simpl(tf(Y1) - rmvX, tol);
    ZIN2 = invert_zpk(YIN2);
    [H3, K] = rmv_pole2(ZIN2, wp);
    K = real(K);
    elem2 = ladderElem(0, 1/K, 0, -wp/K, 'SRC');
    rmvP = tf([K], [1 -wp]);
    Y2 = 1/rmvP;
    H4 = simpl(tf(ZIN2) - rmvP, tol);
    Yrem = minreal(invert_zpk(H4), tol);
%   Yrem = simpl2(H3, 2e-5);
