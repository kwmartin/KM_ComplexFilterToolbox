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

function h = dlogKK_dp(sys,px,s)
% This is a simple program for calculating the derivative of the log of the
% magnitude of system Kz_ with respect to the loss poles.
% sys should be the LTI object.
% s is the frequencies of the minima
% The final matrix h returned has one row for each minima frequency and one
% column for each moveable loss-pole

ls = length(s); % Number of frequency minima
[z,p,k] = zpkdata(sys); % Get zeros and poles

% delete any imagainary residues and then convert to positive
p_ = abs(real(p{1}));
p_ = sort(p_); % Sort
np = length(p_);

% delete every second pole as all poles are repeated at least twice
p_ = p_(1:2:np-1);
np_ = np/2;

% get rid of loss poles with multiplicity greater than 1
% indx = [abs(p_(1:np_-1) - p_(2:np_)) > 10*eps; 1];
% p_ = p_(logical(indx));

% Delete poles at 1, as these are unmoveable and correspond to poles at inf.
p_ = p_(p_~=1);

% Delete fixed poles
for i=1:length(px)
    p_ = p_(abs(p_ - px(i)) > 1e-7);
end

p_ = p_.'; % Convert to row
np_ = length(p_);

pz2 = p_.^2; % Calculate squares of pole frequencies
s = s.'; % Convert to column
h = zeros(ls,np_); % Matrix size

for i = 1:ls % For each frequency
  p2 = pz2 - s(i)^2; % Calculate row vector
  if any(p2==0) % Don't divide by zero
	 h(i,:) = Inf;
  else
	 h(i,:) = -4*(p_./p2); % Calcuate row of derivatives of ln(Kz_*Kz_')
  end
end
