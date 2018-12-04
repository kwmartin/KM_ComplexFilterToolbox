function Fltr = dsgnAnalogFltr(p,px,ni,wp,ws,as,Ap,type)
%   Design a continuous-time transfer function to meet specificatios
%   ws (stop-band edge frequencies), as (relative loss at ws - only effects
%   weighting of negative stop-band vs. positive stop-band, Ap (pass-band
%   maximum deviation in db). p is initial values for moveable poles; actual
%   values are not significant as long as they are in stop-band; px is fixed
%   poles, often used to guarantee a pole at dc; ni is the number of
%   loss-poles at infinity.
%   The transfer function returned has a pass-band centered on dc; it should be
%   denormalized by the inverses of sclFctr, and shftFctr; this might be done
%   in the ladder filter (assuming a ladder filter is to be designed);
%   otherwise it can be done on the transfer function using freqScale(H,
%   1/sclFctr) and freq_shift(H2, -shftFctr).
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

  % Suppress warnings due to Matlab not supporting complex system objects
  % The tool-box is designed to take Matlab limitations into account
  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsA(p, px, wp, ws, as);

  ONE_STP = 0;
  [H1, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,type);
  % Return a struct with important components to make life simpler
  Fltr = struct('H', H1, 'E', E, 'F', F, 'P', P, 'e_', e_, ...
    'sclFctr', sclFctr, 'shftFctr', shftFctr);
  a=1;