function Fltr = dsgnDLddrProto(p,px,ni,wp,ws,as,Ap,type)
% Fltr = dsgnDLddrProto(p,px,ni,wp,ws,as,Ap,type) designs a prototype transfer function
% the protoype transfer function is continuous-time and has a stop-band that
% is between -1 and +1. The specifications are: p: moveable poles, px: fixed poles,
% ni: number of fixed poles at infinity, wp: pass-band edge frequencies, ws: stop-band
% frequencies corresponding to as: stop-band attenuations at ws frequencies, only differences
% are material, and type: either "montonic" or "ellicptic". The Fltr returned is a Matlab
% structure that contains: H: the prototype transfer fucntion, E: the transfer function poles,
% F: the transfer function reflection zeros, P: the loss poles (sometimes called transmission zeros)
% e_: the magnitude pass band is given by (1 + e_^2), sclFctr: the scale factor used to make the pass-band
% width equal to 2 rad., and shftFctr: the shift factor used to center the passband at dc. 1/sclFctr and
% -shftFctr can be used to transform the filter back to the desired specification frequencies.
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
  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  %sclFctr = 1/(2*pi*max(abs(wp)));
  [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as);

  ONE_STP = 0;
  [H1, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,type);
  %plot_crsps(H1,wp,ws,'b',[-10 10 -100 1]);
  Fltr = struct('H', H1, 'E', E, 'F', F, 'P', P, 'e_', e_, ...
  'sclFctr', sclFctr, 'shftFctr', shftFctr);
a=1;