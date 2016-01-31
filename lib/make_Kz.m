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

function Kz_ = make_Kz2(p,px,type)
% make_Kz is used to form zpk system given the finite poles and the number
% of poles at infinity

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

switch type
    case 'elliptic'
		% fz is even part of pz
		fz = (tf(pz) + tf(pz)')/2;
		fz = zpk(fz);
    case 'monotonic'
		N = np;
		P = pz.z{1};
		fz0 = prod(P)^(1/(2*N));
		fz1 = zpk(j*[fz0 -fz0], [], 1);
		fz = fz1^(N);
    otherwise
        error('The third argument must be either elliptic or monotonic');
end

Kz_ = zpk(fz.z{1,1},pz.z{1,1},1);
kz_ = 1.0/abs(freqresp(Kz_,0));
Kz_ = kz_*Kz_;
