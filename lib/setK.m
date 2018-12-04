function [Ply] = setK(fun, Ply)
%   [Ply] = setK(fun, Ply) changes the K of Ply so values of fun and Ply match between roots
%   it is used when choosing the roots of Ply to match fun
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

    rts = Ply.rts;
    N = Ply.N;
    if N >= 2
        ind1 = floor(N/2);
        ind2 = ind1 + 1;
        eval = (rts(ind1) + rts(ind2))/2;
    elseif N == 1
        eval = rts(1)*1.5;
    else
        eval = 0;
    end
    indic = find(abs(rts - eval) < 1e-4);
    while ~isempty(indic)
        eval = eval + 0.2j;
        indic = find(abs(rts - eval) < 1e-4);
    end
    Ply.K = (fun(eval)/Ply.peval(eval))*Ply.K;
    Ply.K = real(Ply.K); % this might be incorrect; needs to be verified
end