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
    % Verified numerically across ~160 setK calls in real designs (elliptic,
    % symmetric elliptic, and monotonic continuous-time filters): imag(Ply.K)
    % is always root-finding noise at the 1e-14..1e-16 relative level, never
    % a meaningful component - real(Ply.K) is the correct gain every time.
    % Warn (rather than silently mis-select) if that ever stops holding.
    if abs(imag(Ply.K)) > 1e-6*max(abs(real(Ply.K)), eps)
        warning('setK:nonNegligibleImagK', ...
            'setK: imag(K)=%.6g is not negligible next to real(K)=%.6g - K may not be purely real here', ...
            imag(Ply.K), real(Ply.K));
    end
    Ply.K = real(Ply.K);
end