function Kz_ = make_Kz_sym(p_master, px, type)
%   Kz_ = make_Kz_sym(p_master, px, type) returns the characteristic
%   function in z for the symmetric-filter special case (see
%   place_poles_sym.m). p_master contains only the "master" (upper
%   stopband, z in (0,1)) movable loss poles; the mirror (lower stopband)
%   poles are constructed as their exact reciprocals, so the resulting
%   characteristic function is exactly, not just approximately, symmetric
%   about dc. px is the full (both-sided) fixed-pole list, exactly as
%   used by make_Kz.
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

  p_mirror = 1.0 ./ p_master;
  Kz_ = make_Kz([p_master p_mirror], px, type);
