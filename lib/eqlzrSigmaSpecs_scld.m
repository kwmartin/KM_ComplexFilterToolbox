function [sigmaMin, sigmaMax, sigma0] = eqlzrSigmaSpecs_scld()
%   [sigmaMin, sigmaMax, sigma0] = eqlzrSigmaSpecs_scld() returns the
%   all-pass section bounds and starting values, in band units, shared by
%   dsgnEqlzrDX_scld (as sigma, the distance of an x-domain pole from the
%   imaginary axis) and dsgnEqlzrDZrel_scld (mapped to a radius).
%
%   They are dsgnEqlzrD's own absolute radius bounds [0, 0.995] and starting
%   radii [0.5 0.75 0.85 0.95] converted with sigma = (1 - r)/((1 + r)*t)
%   at a reference band 0.05 cycles wide (the dsgnEqlzrD_manual example),
%   so at that width all three designs start from the same poles.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2026  Kenneth Martin
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

  BW_REF = 0.05;
  tRef = tan(pi*BW_REF/2);
  r2sig = @(r) (1 - r)./((1 + r)*tRef);
  sigmaMin = r2sig(0.995);
  sigmaMax = r2sig(0);
  sigma0 = r2sig([0.5, 0.75, 0.85, 0.95]);
end
