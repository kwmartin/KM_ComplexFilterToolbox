e_ = sqrt(10^(0.1/10) - 1.0);
[H, E, F, P] = elliptic_dbp(ps,wp,0,e_)
fz
pz
Kz = zpk(fz,pz,1);
zrs = fz.z{1}
pls = pz.z{1}
Kz = zpk(zrs,pls,e_);
KzKz_ = Kz*Kz';
HzHz_ = zpk(1 + tf(KzKz_));
