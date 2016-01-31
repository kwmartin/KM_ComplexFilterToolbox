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

function h = dlogKK_dz(sys,s)
% This is a simple program for calculating the derivative of the log of the
% magnitude of K with respect to z. sys should be the LTI system K.

[z,p,k] = zpkdata(sys);
ls = length(s);
h = zeros(ls,1); % More convenient for loop below

z_ = sort(abs(z{1}));
nz = length(z_);
fz = z_(1:2:nz-1);
fz2 = fz.^2;
p_ = sort(real(p{1}));
np = length(p_);
pz = p_(1:2:np-1);
pz2 = pz.^2;

for i = 1:ls
  z2 = s(i)^2 + fz2;
  p2 = pz2 - s(i)^2;
  if any(z2==0)
	 h(i) = Inf;
  elseif any(p2==0)
      h(i) = Inf;
  else
	 h(i) = 4*(sum(s(i)./z2) + sum(s(i)./p2));
  end
end

