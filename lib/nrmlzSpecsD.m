function [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as)
%   shift specs of digital filter to 0, then predistorts specs assuming a bilinear
%   transform will be used and then scale passband wp to -1,1
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
  shftFctr = -(wp(1) + wp(2))/2;
  [p, px, wp, ws] = shiftSpecs(p, px, wp, ws, shftFctr);
  if length(ws) == 4
    % shiftSpecs is plain elementwise addition (no wraparound), so a ws
    % edge originally very close to +-0.5 (a near-Nyquist sentinel, e.g.
    % -0.49999/0.49999) can land outside [-0.5, 0.5] once shifted by a
    % nonzero shftFctr -- predistortSpecs's own docstring requires all
    % spec frequencies to stay within that range. Confirmed via
    % examples/dig_linPh_1_8_0.m: wp=[0.05 0.06] gives shftFctr=-0.055,
    % and ws(1)=-0.49999 shifts to -0.55499. Since tan(pi*x) has period
    % 1, tan(pi*-0.55499) and tan(pi*0.44499) (this file's own shifted
    % ws(4)) are numerically almost identical, so the out-of-range edge
    % and the file's own far edge collapse onto nearly the same analog
    % frequency after predistortSpecs's tan() warp -- which is exactly
    % what place_polesdLP3 was reporting as "too few independent
    % stop-band loss minima" (a corrupted/duplicated spec, not a real
    % pole-count/passband feasibility limit).
    %
    % Fix: the outer two ws entries are meant to be fixed near-Nyquist
    % sentinels, not quantities that should move with the passband -
    % unlike the inner two (the near-passband edges, which do need to
    % track wp and stay safely away from +-0.5 regardless). So once
    % shiftSpecs has done its job, unconditionally reset the outer two
    % to the fixed, always-in-range values, discarding whatever the
    % shift computed for them. Scoped to length(ws)==4 (the near-
    % universal convention across this toolbox's digital examples) -
    % examples with a 2-point ws (a single inner stopband pair, no outer
    % sentinels: csc_fltr_1_2_0/1_2_1/1_2_1b.m, dfltr_1_2.m) or more
    % than 4 (genuine multi-band stopbands: dfltr_1_6_1.m, 1_7_1.m) are
    % deliberately left on the unmodified path.
    ws([1 4]) = [-0.499 0.499];
  end
  [p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs
  sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);
  a=1;
