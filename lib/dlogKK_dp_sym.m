function h_sym = dlogKK_dp_sym(sys, px_full, p_master, s_master)
%   h_sym = dlogKK_dp_sym(sys, px_full, p_master, s_master) computes the
%   sensitivity matrix for the symmetric-filter special case (see
%   place_poles_sym.m) by calling the existing dlogKK_dp on the full
%   (master+mirror) pole set and folding each mirror pole's column into
%   its master pole's column, using the exact chain-rule relationship for
%   the reciprocal mapping p_mirror = 1/p_master (d(1/x)/dx = -1/x^2). No
%   new derivative formula is introduced here.
%
%   px_full must be the FULL fixed-pole list (both master- and mirror-side,
%   including any poles at 1), not master-only -- dlogKK_dp excludes fixed
%   poles from its movable columns, so passing a master-only subset would
%   misclassify mirror-side fixed poles as movable.
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

  np2 = length(p_master);
  h_full = dlogKK_dp(sys, px_full, s_master);
  np = size(h_full, 2);
  if np ~= 2*np2
      error('dlogKK_dp_sym:columnMismatch', ...
        ['dlogKK_dp_sym: dlogKK_dp returned %d movable-pole columns, ' ...
         'expected %d (2x the %d master poles). The pole set passed in ' ...
         'is not symmetric as expected.'], np, 2*np2, np2);
  end

  h_sym = zeros(length(s_master), np2);
  for jcol = 1:np2
      h_sym(:,jcol) = h_full(:,jcol) - h_full(:, np+1-jcol) ./ (p_master(jcol)^2);
  end
