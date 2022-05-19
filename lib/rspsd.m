function h = rspsd(sys,s)
% This is a program for calculating the response of a zpk discrete-time system.
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.


[z,p,k] = zpkdata(sys); % Find the zeros and poles
ls = length(s); % Find the number of frequency points
hlg = zeros(ls,1); % More convenient for loop below

eS = exp(s);
for i = 1:ls % Iterate for each frequency
    zs = eS(i) - z{1}; % Calculate the vector of zeros; z is array of coefficients possibly complex
    indxz = (zs == 0);
    zs(logical(indxz)) = 10*eps;
    ps = eS(i) - p{1};% Calculate the vector of poles
    indxp = (ps == 0);
    ps(logical(indxp)) = 10*eps;
    hlg(i) = sum(log(zs)) - sum(log(ps)); % Use builtin functions to simplify
 end
h = k.*exp(hlg);
