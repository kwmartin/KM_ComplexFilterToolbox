trnc = @(val, d) (fix(val*2^d) + rand())/2^d;

N = 64; % Filter order
K = 4; % ratio of filter order to number of channels
M = N/K; % the number of channels

Gis = [-0.23514695, 0.70710681, -0.97195983, 1.0, ...
    -0.97195983, 0.70710681, -0.23514695];

P = proto(N,K);

% Get space for the coefficients for all transmit filters

T=zeros(M,N);
R=zeros(M,N);

T(1,:)=P;

[T, R]=quam_flt(N,4);

npts = 512;
f0 = 1/16;
% f0 = 0;
dPh = 1/64;
fFl = f0-3*dPh : dPh : f0+3*dPh;
% fFl = fFl.';
fFl = f0-3*dPh;
X = zeros(npts,7);
TF = zeros(npts,1);
for i = 1:7
    x = gnrtCmplxd(fFl, npts, 0);
    X(:,i) = x;
    TF = TF + Gis(i) * x;
    fFl = fFl + dPh;
end
RF = zeros(npts,1);
RF(1:npts)=conj(TF(npts:-1:1));
% TF1 = trnc(TF(1:N), 12);
TF1 = TF(1:N)
RF1 = trnc(RF(1:N), 30);
TT = conv(TF1,RF1)./256;
db(1 - abs(TT(64)))
% yout = zeros(256,1);
% X0 = gnrtCmplxd(fFl, npts, 0);

w_diff=2*pi/M;
W=diag(exp(-j*w_diff).^(0:N-1));
for i = 2:M
    T(i,:)=T(i-1,:)*W;
end
% Note: T(i,:) is the FIR filter that generates the i'th IFT

% Next we multiply all coefficients of adjacent filters by j
% phase offset.
% The j difference between filters is to eliminate cross-talk between adjacent
% filters.
% The phase offset is added so that there will be conjugate symetry about dc.

T2=diag((j).^(0:N/K-1))*T;
% Note: T2(i,:) have adjacent filters phase shifted by pi/4 so real and
% imaginary data has has no inter-symbol interference.
xr = zeros(npts,1);
xr(1) = 1;
yr=filter(TF,1,xr);
figure;
plot(real(yr));
hold on;
plot(imag(yr));
hold off;
xi = zeros(npts,1);
xi(1) = 1;

yout =filter(TT,1,xi(1:256));
dB = plotRspnsd(yout, [-160, 2], true);
db(abs(yout(64) - 1))

% y1 = filter(TF1,1,xi(1:npts));
y1 = filter(TF1,1,xi(1:npts));
y2 = filter(RF1,1,y1);
y3 = y2/256;

y4 = zeros(npts,1);
y5 = zeros(npts,1);
y4(1) = y1(1);
for i = 1:64
    y5(i) = 0;
    for jj = 1:64
        y5(i) = y5(i) + RF1(jj)*y4(jj);
    end
    for indx = 64:-1:2
        y4(indx) = y4(indx-1);
    end
    y4(1) = y1(i+1);
    a = 1;
end
y6 = y5/256;

y_1 = firFlt(TF1,xi(1:npts));

yi=filter(TF1,1,xi);
figure;
plot(real(yi));
hold on;
plot(imag(yi));
hold off;

% dB = plotRspnsd(TF(1:64), [-130, 2], true);
dB = plotRspnsd(TF(1:64), [-130, 2]);

o0 = 0;
for i = 1:N
    o0 = o0 + y1(i)*RF1(N-i+1);
    % o0 = o0 + y1(i)*RF1(i);
end
db(abs(o0/256) - 1)

xMem = zeros(M,1);
indx = 1;
iaccm = 0;
x3 = 0;
mpRsps = zeros(npts,1)
for i = 1:npts
    x4 = xMem(mod(i, M) + 1);
    xMem(mod(i, M) + 1) = xi(i);
    x1 = xi(i) - x4;
    x2 = TF(i,1).*x1;
    x3 = x2;
    impRsps(i) = x1;
end
dB = plotRspnsd(impRsps, [-130, 2], true);
a = 1;
