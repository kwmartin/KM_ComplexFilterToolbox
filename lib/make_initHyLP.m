function Hy = make_initHyLP(e,p,px,ni,wp)
%   Hy = make_initHyLP(e,p,px,ni,wp) returns transformed Hy with initial poles
%   z2y = @(z,wi)(-j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
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

z2y = @(z,wi)(j.*(2.*(z - 1) - j.*wi(2).*(z + 1))./(2.*(z - 1) - j.*wi(1).*(z + 1)));
w1 = wp(1);
w2 = wp(2);
np = length(p); % number of finite loss poles (including zero)

% transform movable loss poles to z
p_ = [];
for i = 1:np
    p_(i) = z2y(p(i),wp);
end

nx = length(px); % number of finite loss poles (including zero)

% transform fixed loss poles to z
for i = 1:nx
    p_(np+i) = z2y(px(i),wp);
end

% add loss poles at 1 in in z which correspond to infinity in s
p_ = [p_ j*ones(1,ni)];
p_ = sort(p_);
np = np + nx + ni;

% transform e zeros to y
ne = length(e);
z_ = [];
for i = 1:nz
    z_(i) = z2y(e(i),wp);
end

Hy = zpk(z_,p_,1); % Note gain is not preserved, will adjust later
