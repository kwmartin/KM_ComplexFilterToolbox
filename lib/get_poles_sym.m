function [p_master, np_master, px_master, nx_master] = get_poles_sym(sys, px_full)
%   [p_master, np_master, px_master, nx_master] = get_poles_sym(sys, px_full)
%   returns the "master" (upper stopband, z in (0,1)) half of the movable
%   and fixed loss poles for the symmetric-filter special case (see
%   place_poles_sym.m). Validates that the full movable pole set returned
%   by get_poles is exactly reciprocal-paired (p(i)*p(np+1-i) ~= 1), as
%   required for exact complex-conjugate (mirror) symmetry, and errors
%   clearly if not. px_full must include any poles at 1 (i.e. loss poles
%   at infinity, from ni); those are self-mirrored and are excluded from
%   px_master (the caller already knows ni and can re-add the z=1
%   boundary explicitly where needed).
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

  tol_init = 1e-3; % loose: checks the caller's initial guess, not a converged iterate

  [p_full, np_full] = get_poles(sys, px_full);

  if mod(np_full, 2) ~= 0
    error('get_poles_sym:oddPoleCount', ...
      ['get_poles_sym: movable pole count (%d) is odd, so the poles cannot ' ...
       'be paired into an exact mirror-symmetric set. The filter spec ' ...
       '(p, px, wp, ws, as) is not symmetric.'], np_full);
  end

  np_master = np_full/2;
  for i = 1:np_master
    prod_i = p_full(i)*p_full(np_full+1-i);
    if abs(prod_i - 1) > tol_init
      error('get_poles_sym:notReciprocal', ...
        ['get_poles_sym: pole %d (%.6g) and pole %d (%.6g) are not a ' ...
         'reciprocal (mirror) pair (product=%.6g, expected 1). The filter ' ...
         'spec is not symmetric.'], i, p_full(i), np_full+1-i, p_full(np_full+1-i), prod_i);
    end
  end
  p_master = p_full(1:np_master);

  % Fixed poles at exactly 1 (loss poles at infinity, from ni) are self-mirrored
  % and are excluded here; any other fixed poles must pair up reciprocally.
  px_rest = sort(px_full(abs(px_full - 1) >= 1e-9));
  nx_rest = length(px_rest);
  if mod(nx_rest, 2) ~= 0
    error('get_poles_sym:oddFixedPoleCount', ...
      ['get_poles_sym: fixed pole count (excluding poles at infinity) is ' ...
       'odd (%d); cannot be symmetric.'], nx_rest);
  end
  nx_master = nx_rest/2;
  for i = 1:nx_master
    prod_i = px_rest(i)*px_rest(nx_rest+1-i);
    if abs(prod_i - 1) > tol_init
      error('get_poles_sym:fixedNotReciprocal', ...
        ['get_poles_sym: fixed pole %.6g and fixed pole %.6g are not a ' ...
         'reciprocal (mirror) pair (product=%.6g, expected 1). The filter ' ...
         'spec is not symmetric.'], px_rest(i), px_rest(nx_rest+1-i), prod_i);
    end
  end
  px_master = px_rest(1:nx_master);
  nx_master = length(px_master);
