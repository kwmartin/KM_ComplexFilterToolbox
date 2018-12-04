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

function [p,np] = get_poles(sys,px)
% This function returns the loss poles excluding the fixed
% loss-poles corresponding to px .

% delete imagainary part and then convert to positive
p_ = abs(real(sys.p{1}));
p_ = sort(p_);
np = length(p_);

% delete every second pole as all poles are repeated
p_ = p_(1:2:np-1);
np_ = np/2;

% get rid of loss poles with multiplicity greater than 1
% indx = [abs(p_(1:np_-1) - p_(2:np_)) > 1e-7; 1];
% p_ = p_(logical(indx));

% Delete fixed poles
for i=1:length(px)
    p_ = p_(abs(p_ - px(i)) > 1e-7);
end

p = p_.';
np = length(p_);


