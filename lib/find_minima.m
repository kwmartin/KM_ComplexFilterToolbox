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

function zmin = find_minima(sys,ws,as,wp)
% This is a simple program for finding the minima of Kz_*Kz_'  in the z plane
% Note that z is equiv. to s', not the z variable used in discrete-time filters
% The minima of Kz_Kz_' are all assumed to be between the loss poles.
% Loss poles at 0 in z correspond to jw2 in s
% Loss poles at inf in z correspond to jw1 in s
% Loss poles at 1 in z correspond to inf in s
% each loss pole is repeated twice (at least) and normally negative

[z,p,k] = zpkdata(sys); % Get the zeros and poles

NPTS = 200;
p_ = abs(real(p{1})); % Delete any imagainary residue and then convert to positive
p_ = sort(p_); % Sort
np = length(p_); % Find length

p_ = p_(1:2:np-1); % Delete every second pole as all poles are repeated
np_ = np/2; % Correct order

% Get rid of loss poles with multiplicity greater than 1
indx = [abs(p_(1:np_-1) - p_(2:np_)) > 1e-7; 1];
p_ = p_(logical(indx));
np_ = length(p_);

winit = sqrt(p_(1:np_-1).*p_(2:np_)); % Calculate initial guesses of minima as geometric averages
% now look at spaced points between the poles and choose the one with the
% smallest margin as the initial guess (to try and get around local minima)
for k = 1:np_-1
    dw = (p_(k + 1) - p_(k))/NPTS;
    w = p_(k):dw:p_(k + 1);
    m10 = find_margin2(sys,ws,as,wp,w);
    [min1 i] = min(m10);
    wmin = w(i);
    if min1 < find_margin2(sys,ws,as,wp,winit(k))
        winit(k) = wmin;
    end
end
zmin = winit.';
% wmin = z2s(zmin,wp)
return

for k = 1:np_-1 % Iterate for each minima
    w1 = winit(k);
    w2 = w1 + 1e-5; % Used to calculate estimate of second derivative
    FPrime = 1; % Initialize second derivative
    for i = 1:25 % Iterate enough times to guarantee convergence, 15 is adequate
        % F1 = dlogKK_dz(sys,w1) + dAs10_dz(wsz,As,w1); % Find vector of first derivatives at w1
        % F2 = dlogKK_dz(sys,w2) + dAs10_dz(wsz,As,w2); % Find vector of first derivatives at w2
        % F1 = dlogKK_dz(sys,w1); % Find vector of first derivatives at w1
        % F2 = dlogKK_dz(sys,w2); % Find vector of first derivatives at w2
        F = dlogKK_dz(sys,[w1 w2]); % Find vector of first derivatives at w1
        dA_dw = dAs10_dz(wsz,As,[w1 w2]);
        F1 = F(1) - dA_dw(1);
        F2 = F(2) - dA_dw(2);
       if (w2 - w1)~=0 % Do not divide by zero
            FPrime = (F2 - F1)./(w2 - w1); % Calculate second derivative using difference equat.
        end
        w1 = w2;
        w2 = w2 - F2./(FPrime + 1e-16); % Update minima; do not divide by zero
         % This check for convergence and early termination is not necessary.
         % I couldn't keep myself from including. Typical termination is for i = 4 to 8
        if max(abs(w1 - w2)) < 5*eps
            % disp('Minima Iteration Terminated')
            % i
            break
        end
	end
    zmin(k) = w2;
end
% zmin.'
if np_<=1 % Look after special case of no moveable loss-poles
    zmin = [];
end
