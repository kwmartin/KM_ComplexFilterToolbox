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
  % NOTE: shiftSpecs is plain elementwise addition (no wraparound), so a
  % ws edge originally very close to +-0.5 can land outside [-0.5, 0.5]
  % once shifted by a nonzero shftFctr. A fix was tried here (force the
  % outer two ws entries back to -0.499/+0.499 after shifting, when
  % length(ws)==4) but reverted: predistortSpecs (below) already
  % prepends/appends its own fresh -0.499/+0.499 sentinels unconditionally,
  % so this duplicated that -- and for filters whose own ws legitimately
  % used a different boundary (e.g. csc_fltr_1_8_0.m's ws=[-0.49 ... 0.49]),
  % forcing it to -0.499 collided EXACTLY with predistortSpecs's own fresh
  % -0.499, producing a genuine duplicate sample point and breaking
  % interp1 in find_margin2.m for every elliptic/monotonic design that
  % reaches it (confirmed: 18 regressions across csc_fltr_*/DLddrFltr_*/
  % dsgnEqlzrD_*/eqlz_csc_*/FltrBnk_* in a full-suite run). The actual
  % fix for the dig_linPh_1_6_0.m/1_8_0.m failures this was originally
  % written for turned out to be entirely in adaptP3.m/place_polesdLP3.m
  % (their Newton loops' collision/drift handling) -- ws is never even
  % consumed by place_polesdLP3's 2-arg form, which is what those two
  % examples actually use, so this fix was never the right target.
  [p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs
  sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
  [p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);
  a=1;
