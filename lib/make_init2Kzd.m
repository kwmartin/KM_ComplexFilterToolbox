function Kz_ = make_init2Kzd(p,px,ni,wp,type)
%   Kz_ = make_init2Kzd(p,px,ni,wp,type) returns initial characteristic function in z
%   Note: z is not the inverse delay operator (e^jwT), rather
%   z = sqrt((s - j*wp(2))./(s - j*wp(1)))
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
%   In s, H(s)H(-s) = 1 + K(s)K(-s) where K(s) is the characteristic function
%   We have K(s)K(-s) = e^2 (F(s)F(-s))/(P(s)P(-s)) (e is epsilon)
%   Kz_ is K(s)K(-s) transformed to z domain

w1 = wp(1);
w2 = wp(2);
np = length(p); % number of finite loss poles (including zero)

% transform movable loss poles to z
p_ = [];
for i = 1:np
    p_(i) = s2zd(j*p(i),wp);
end

nx = length(px); % number of finite loss poles (including zero)

% transform fixed loss poles to z
for i = 1:nx
    p_(np+i) = s2zd(j*px(i),wp);
end

% add loss poles at 1 in in z which correspond to infinity in s
p_ = [p_ ones(1,ni)];
p_ = sort(p_);
np = np + nx + ni;

p_2 = -repmat(p_,1,2);
pz = zpk(p_2,[],1);

switch type
  case 'elliptic'
    p1 = polyClass(pz.z{1}, 1);
    [fev, fodd] = getEvnOddPly(p1);
    fz = zpk(fev.rts,[],1);
% I can't help myself: there is so much history behind these two lines, incredible! KM
  case 'monotonic'
    N = np;
    fz0 = prod(p)^(1/np);
    num = sortImag(fz0.*repmat([j -j], 1, np));
    fz = zpk(num, [], 1);
  otherwise
    error('The third argument must be either elliptic or monotonic');
end

% Now that we have Fz^2, Kz_ is simply Fz^2/Pz^2
Kz_ = zpk(fz.z{1,1},pz.z{1,1},1);
kz_ = 1.0/abs(freqresp(Kz_,0));
Kz_ = kz_*Kz_;
