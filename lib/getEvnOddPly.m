function [Eevn, Eodd] = getEvnOddPly(Epl)
%   Find even and odd parts of a polynomial object
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

rts = Epl.rts;
if isempty(find(abs(real(rts)) > 1e-5))
    if mod(Epl.N, 2) == 0
        Eevn = polyClass(Epl);
        Eodd = polyClass();
    else
        Eevn = polyClass();
        Eodd = polyClass(Epl);
    end
    return
end
Etf = poly(rts);
Netf = length(Etf);
if mod(Netf, 2) == 1
    sgns = (-1).^(0:(Netf-1));
else
    sgns = (-1).^(1:(Netf));
end
Etfevn = (Etf + conj(Etf).*sgns)/2;
Etfevn = reduceLeadTF(Etfevn);
Etfodd = (Etf - conj(Etf).*sgns)/2;
Etfodd = reduceLeadTF(Etfodd);
Nevn = length(Etfevn) - 1;
Nodd = length(Etfodd) - 1;

% Now that we know the order we find the roots
% of the even and odd polynomials using more 
% accurate zero finding based on Muller

Epl2 = Epl'; % Epl2 = conj(Epl(-s))
funEvn = @(s) (Epl.peval(s) + Epl2.peval(s))/2.0;
funOdd = @(s) (Epl.peval(s) - Epl2.peval(s))/2.0;
Eevn = polyClass();
Eevn.K = 1;
Eodd = polyClass();
Eodd.K = 1;

N = Epl.N;
Init = [-2j j 3j];
tol = 1e-14;
maxIter = 1000;

if Nevn <= 1
    Evn.rts = [];
    Evn.K = 0;
else
    val= muller(funEvn,Eevn,Nevn,Init,tol,maxIter);
    Eevn.cleanRts();
    Eevn = setK(funEvn, Eevn);
end

if Nodd < 1
    Eodd.rts = [];
    Eodd.K = 0;
else
    val= muller(funOdd,Eodd,Nodd,Init,tol,maxIter);
    Eodd = setK(funOdd, Eodd);
    Eodd.cleanRts();
end
a=1;