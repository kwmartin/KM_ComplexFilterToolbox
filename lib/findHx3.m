function Hx = findHx3(fz,pz, e_)
%   Hz = findHz3(fz,pz) solves Feldtkeller's equation in the transformed domain
%   It makes use of the muller algorithm in polyClass to accurately sovle
%   Feldtkeller's Algorithm
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
s1 = e_^2*KKz;
zrts = imag(s1.z{1})*j;
prts = real(s1.p{1});
f1 = polyClass(zrts, s1.k);
p1 = polyClass(prts, 1);

N=p1.N;
rtsf=-f1.rts(1:f1.N/2).*f1.rts(f1.N:-1:f1.N/2+1);
rtsp=-p1.rts(1:p1.N/2).*p1.rts(p1.N:-1:p1.N/2+1);
p2 = polyClass(rtsp, p1.K);
f2 = polyClass(rtsf, f1.K);
nh2 = f2 + p2;
nh2.rts;
nh_rts = sortRoots([sqrt(nh2.rts); -sqrt(nh2.rts)]);
nh_ = polyClass(nh_rts, nh2.K);

rtzh = nh_rts(imag(nh_rts) > 0);
rtzh = rtzh(real(rtzh) > 0);
rtszh = sortRoots([rtzh; -rtzh]);
rtph = sqrt(rtsp);
rtph = rtph(1:2:end-1);
rtsph = sort([rtph; -rtph]);
Hx = zpk(rtsph, rtszh, 1);

a = 1;
