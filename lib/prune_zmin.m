function zmino = prune_zmin(p,px_,zmin)
% deletes elements of zmin when adjacent poles are both fixed
%
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
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

% add pass-band edges (in z) to fixed poles as we don't want minimums
% betwee pass-band eges and fixed poles
% px_ = [0 px_ 1e6];

zmino = [];
pls = sort([p px_]);
for i = 1:length(zmin)
    zmn = zmin(i);
    p1 = max(pls(find((zmn - pls) > 0))); % find closest pole below zmn
    p2 = min(pls(find((pls - zmn) > 0))); % find closest pole above zmn
    % check if both are fixed poles; if so, don't include zmin
    if (any(abs(px_ - p1) < 1e-16)) & (any(abs(px_ - p2) < 1e-16))
        continue
    else
        zmino = [zmino zmn];
    end
end
return
