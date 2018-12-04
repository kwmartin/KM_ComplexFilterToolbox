function Kz_ = make_Kz2(p,px,type)
%   Kz_ = make_Kz2(p,px,type) returns characteristic function in z
%   Note: z is not the inverse delay operator (e^jwT), rather
%   z = sqrt((s - j*wp(2))./(s - j*wp(1)))
%   In s, H(s)H(-s) = 1 + K(s)K(-s) where K(s) is the characteristic function
%   We have K(s)K(-s) = e^2 (F(s)F(-s))/(P(s)P(-s)) (e is epsilon)
%   Kz_ is K(s)K(-s) transformed to z domain
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


np=length(p); % number of finite loss poles (including zero)
nx = length(px); % number of fixed poles

% add fixed poles and poles at 1 (for infinity in s)
p = [p px];
p = sort(p);
np = np + nx ;

psq = p.*p;
pz = zpk([],[],1);
for i = 1:np
    pp(i) = zpk(tf([1 2*p(i) psq(i)],1));
    pz = pz* pp(i);
end

% This is one of the most significant sections of this toolbox
% see:  A. Sedra and P. Brackett, Filter Theory and Design: Active and Passive.
% Matrix Publishers, 1978.
switch type
  case 'elliptic'
    % fz is even part of pz, Sedra eqn 4.85
    % There is so much history behind the next line, incredible! KM
    fz = (tf(pz) + tf(pz)')/2;
    fz = zpk(fz);
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

Kz_ = zpk(fz.z{1,1},pz.z{1,1},1);
kz_ = 1.0/abs(freqresp(Kz_,0));
Kz_ = kz_*Kz_;
