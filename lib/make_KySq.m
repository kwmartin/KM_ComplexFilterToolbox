function KySq = make_KySq(p,px,type)
%   KzSq = make_KySq(p,px,type) returns characteristic function in y
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

p_2 = -repmat(p,1,2);
pz = zpk(p_2,[],1);

switch type
  case 'elliptic'
    p1 = polyClass(pz.z{1}, 1);
    [fev, fodd] = getEvOdPly(p1); % KM 11/17/2019 now using polyClass functions
    fz = zpk(fev.rts,[],1);

  case 'monotonic'
    N = np;
    fz0 = prod(p)^(1/np);
    num = sortImag(fz0.*repmat([j -j], 1, np));
    fz = zpk(num, [], 1);
otherwise
    error('The third argument must be either elliptic or monotonic');
end

Kz_ = zpk(fz.z{1,1},pz.z{1,1},1);
kz_ = 1.0/abs(freqresp(Kz_,0));
Kz_ = kz_*Kz_;

f1 = sortRoots(fz.z{1});
N=length(f1);
f2=-f1(1:N/2).*f1(N:-1:N/2+1);
f2 = f2(:).';
f3 = repmat(f2,1,2);
p2 = p.^2;
p3 = repmat(p2,1,2);
KySq = zpk(f3, p3, 1);
ky_ = 1.0/abs(freqresp(KySq,0));
KySq = ky_*KySq;

A = 1;
