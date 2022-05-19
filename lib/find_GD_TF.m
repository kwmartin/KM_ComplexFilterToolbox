function h1 = find_GD_TF(h0)
% h2 = find_GD_TF(h1) finds the transfer function that is the derivate of
% the log(h1). The -1 times the real part of this transfer function is the
% group delay
%
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

h0 = zpk(h0);
h0z = h0.z{1};
h0p = h0.p{1};
z = tf('z',1);
gtz = tf(0,[1],1);
for i=1:length(h0z)
    gtz = gtz + z/(z -h0z(i));
end
gtp = tf(0,[1],1);
for i=1:length(h0p)
    gtp = gtp + z/(z -h0p(i));
end
gtf = gtz - gtp;
h1 = simpl(gtf);
a = 1;
