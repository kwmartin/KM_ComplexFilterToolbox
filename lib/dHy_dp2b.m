function sens = dHy_dp2b(Hy,w)
% sens = dHy_dp2b(Hy,w) returns the sensitivites of d(log(abs(Hy)/dp
% The final matrix h returned has one row for each minima frequency and one
% column for each moveable loss-pole. This version separates out loss-poles at 1
% which corresponds to -1 and does not include them
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

ls = length(w); % Number of frequency minima
[z, p, k] = sortZPK(Hy);

np = length(p);
p = p.'; % Convert to row

p2 = imag(p);
p3 = p2(abs(p2 - 1) > 1e-7);
np = length(p3);

w = w(:); % Convert to column
sens = zeros(ls,np); % Matrix size

for i = 1:np
    pden = w - p3(i);
    sens(:,i) = 1./(pden);
end
a = 1;