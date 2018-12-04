function Kz_ = make_init2Kz2(p,px,ni,wp,type)
%   Kz_ = make_init2Kz2(p,px,ni,wp,type) returns initial characteristic function in z
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
    p_(i) = s2z(j*p(i),wp);
end

nx = length(px); % number of finite loss poles (including zero)

% transform fixed loss poles to z
for i = 1:nx
    p_(np+i) = s2z(j*px(i),wp);
end

% add loss poles at 1 in in z which correspond to infinity in s
p_ = [p_ ones(1,ni)];
p_ = sort(p_);
np = np + nx + ni;
% make [pi^2]
psq = p_.*p_;

% We make a zpk system object for each (s + pi)^2
% and then cascade them to overall transfer function
pz = zpk([],[],1);
for i = 1:np
    pp(i) = zpk(tf([1 2*p_(i) psq(i)],1));
    pz = pz * pp(i);
end

% This is perhaps the most significant part of this toolbox
% see:  A. Sedra and P. Brackett, Filter Theory and Design: Active and Passive.
% Matrix Publishers, 1978.
switch type
  case 'elliptic'
    % fz is even part of pz, Sedra eqn 4.85
    fz = (tf(pz) + tf(pz)')/2;
    fz = zpk(fz);
% I can't help myself: there is so much history behind these two lines, incredible! KM
  case 'monotonic'
    N = np;
    %P = pz.z{1};
    %fz0 = prod(P)^(1/(2*N));
    %fz0 = prod(P)^(1/N);
    %fz0 = 1;
    %fz1 = zpk([j*fz0, -j*fz0], [], 1); % one zero at -jfz0 and a zero at jfz0
    %fz = fz1^(2*N); % Note, fz is numerator of K(z)*K'(-z)
    %fz = fz1^(N); % Note, fz is numerator of K(z)*K'(-z)
    num = repmat([j -j], 1, N);
    fz = zpk(num, [], 1);
  otherwise
    error('The third argument must be either elliptic or monotonic');
end

% Now that we have Fz^2, Kz_ is simply Fz^2/Pz^2
Kz_ = zpk(fz.z{1,1},pz.z{1,1},1);
kz_ = 1.0/abs(freqresp(Kz_,0));
Kz_ = kz_*Kz_;
