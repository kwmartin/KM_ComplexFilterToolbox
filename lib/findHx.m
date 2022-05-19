function Hx = findHx(fz,pz, e_)
%   Hz = findHz(fz,pz) solves Feldtkeller's equation in the transformed domain
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
%   Ken Martin: 11/24/03
%   Revised: 10/20/18

Kz = zpk(fz.z{1},pz.z{1},1);
pzn = zpk(-pz.z{1}, [], 1);
Kz_ = zpk(fz.z{1},pzn.z{1},1);
KKz = Kz*Kz_;
HHz = zpk(1 + tf(e_^2*KKz));
zhh1 = sort(HHz.z{1});
zhh2 = abs(real(zhh1)) +j*(abs(imag(zhh1)));
zhh3 = (zhh2(1:4:end-3) + zhh2(2:4:end-2) + zhh2(3:4:end-1) + zhh2(4:4:end))/4;
zhh4 = [zhh3; [-real(zhh3) - j*imag(zhh3)]];
phh1 = sort(real(HHz.p{1}));
phh2 = (phh1(1:2:end-1)+phh1(2:2:end))/2;
Hx = zpk(phh2, zhh4, 1);
a = 1;
