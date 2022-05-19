function sens = dHy_dp(Hy,px,w)
% sens = dHy_dp(Hy,px,w) returns the sensitivites of d(log(abs(Hy)/dp
% The final matrix h returned has one row for each minima frequency and one
% column for each moveable loss-pole
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
% Delete fixed poles
for i=1:length(px)
    p_ = p(abs(p - px(i)) > 1e-7);
end

p_ = p_.'; % Convert to row
np_ = length(p_);

w = w(:); % Convert to column
sens = zeros(ls,np_); % Matrix size

for i = 1:np_
    pden = w - imag(p_(i));
    sens(:,i) = 1./(pden);
end
a = 1;