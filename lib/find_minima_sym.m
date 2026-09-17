function zmin_master = find_minima_sym(sys, ws, as, wp, tol_row)
%   zmin_master = find_minima_sym(sys, ws, as, wp, tol_row) finds the
%   stop-band attenuation minima for the symmetric-filter special case
%   (see place_poles_sym.m). sys is assumed to have been built (e.g. by
%   make_Kz_sym) from an exactly reciprocal-paired pole set; this keeps
%   only the "master" half of the minima. As a diagnostic (not a
%   correctness gate -- the primary defense against a mis-specified
%   caller is place_poles_sym's up-front wp/ws/as palindrome check and
%   get_poles_sym's initial pole-pairing check), it warns if the
%   discarded mirror half looks grossly non-redundant
%   (zmin(k)*zmin(n+1-k) far from 1). This is a warning, not an error,
%   because find_minima's own per-side numerical search (fixed grid +
%   limited Newton refinement) introduces real, sometimes-large relative
%   noise between independently-found master/mirror minima even when the
%   underlying Kz_ is exactly symmetric by construction -- turning this
%   into a hard error was found (empirically) to abort otherwise-healthy,
%   correctly-converging symmetric designs.
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

  if nargin < 5
      % Empirically, find_minima's per-side search noise can transiently
      % reach a few percent even for a genuinely, exactly symmetric Kz_
      % (see place_poles_sym.m); this threshold is set well above that
      % observed noise floor so it only fires for grossly wrong cases.
      tol_row = 0.15;
  end

  zmin_full = find_minima(sys, ws, as, wp);
  nz = length(zmin_full);
  if nz == 0
      zmin_master = zmin_full;
      return
  end

  for k = 1:floor(nz/2)
      resid = abs(zmin_full(k)*zmin_full(nz+1-k) - 1);
      if resid > tol_row
          warning('find_minima_sym:asymmetric', ...
            ['find_minima_sym: minima %d (%.10g) and its mirror %d (%.10g) ' ...
             'look grossly non-reciprocal (product=%.10g, expected 1). This ' ...
             'may indicate the filter spec is not exactly symmetric.'], ...
             k, zmin_full(k), nz+1-k, zmin_full(nz+1-k), zmin_full(k)*zmin_full(nz+1-k));
      end
  end

  nkeep = ceil(nz/2);
  zmin_master = zmin_full(1:nkeep);
