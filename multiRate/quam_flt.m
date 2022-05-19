function [T, R] = quam_flt(n,K)
% function [T, R] = vflt(n,K) is used to find the coefficients of the transmit
% and receive channel bank filters. n is the filter order. K is the ratio
% of the filter order to the number of channels. The rows of T are the
% coeffcients of the transmit filters. The rows of R are the coefficients of
% the receive filters.
% The transmit filters are scaled by 1/(Kn) and the receive filters are scaled
% by 1 for transmultiplexor applications. For unity-gain at the center
% change the scale factors to 1/n for both filters.
% For real channels, just take the real part of the first M/2 rows.

if ((K == 3) | (K == 4) | (K == 6) | (K == 8))
    M = n/K;
else
   error('The ratio of filt. order to the number of filt. must be 3,4,6 or 8');
end

if ((n < 16) | (rem(n,2) ~= 0))
    error('The filter order must even and at least 16.');
end

% Construct the prototype filter

P = proto(n,K);

% Get space for the coefficients for all transmit filters

T=zeros(M,n);
R=zeros(M,n);

T(1,:)=P;

% We next translate the prototype filter from d.c. by 2*pi/(n/(M/2)).
% This will eventually result in conjugate symetry about d.c.
% and no filters at d.c. or Fs/2.
% This has been eliminated for QAM filters

% freq_offset=2*pi/(2*M);
% W=diag(exp(-j*freq_offset).^(0:n-1));
% T(1,:)=T(1,:)*W;

% Next we find the other filters which are separated by 2*pi/(n/K)

freq_diff=2*pi/M;
W=diag(exp(j*freq_diff).^(0:n-1));
for i = 2:M
    T(i,:)=T(i-1,:)*W;
end

% Next we multiply all coefficients of adjacent filters by j
% phase offset.
% The j difference between filters is to eliminate cross-talk between adjacent
% filters.
% The phase offset is added so that there will be conjugate symetry about dc.

T=diag((j).^(0:n/K-1))*T;

R(:,1:n)=conj(T(:,n:-1:1));
T=T./(M);

% The function proto(n,K) is used to get the prototype filter

function P = proto(n,K)
phi = (2*pi/n).*(0:n-1);
switch K
    case 3
	P = 1 - 0.91143783*2.*cos(phi) + 0.41143783*2.*cos(2.*phi);
    case 4
	P = 1 - 0.97195983*2.*cos(phi) + 0.70710681*2.*cos(2.*phi) ...
	- 0.23514695*2.*cos(3.*phi);
    case 6
        P = 1 - 0.99722723*2.*cos(phi) + 0.94136732*2.*cos(2.*phi) ...
        - 0.70710678*2.*cos(3.*phi) + 0.337383417*2.*cos(4.*phi) ... 
	- 0.07441672*2.*cos(5.*phi);
    case 8
        P = 1 - 0.99988389*2.*cos(phi) + 0.99315513*2.*cos(2.*phi) ...
        - 0.92708081*2.*cos(3.*phi) + 0.707106781*2.*cos(4.*phi) ...
        - 0.37486154*2.*cos(5.*phi) + 0.11680273*2.*cos(6.*phi) ...
	- 0.01523841*2.*cos(7.*phi);
end
