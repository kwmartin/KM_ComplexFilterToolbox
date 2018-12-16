function cscdFltr = dsgnCascadeFltr(p,px,ni,wp,ws,as,Ap,type)
% cscdFltr = dsgnCascadeFltr(p,px,ni,wp,ws,as,Ap,type) design cascade filter
% Top level function for designing a cascade filter from specs
% p is a vector containing initial values for moveable poles; they must be in the stop band
% px is a vector containing fixed poles, ni is the number of poles at infinity
% wp is a vector containing the pass-band edge frequencies, ws is a vector containing
% the frequencies at which the stop-band attenation is specified; as is the specifications
% for the the stop-band attenuation in dB; only the differences are material; Ap is the
% specification for the pass-band ripple in dB, type is either "monotonic" or "elliptic"
% Do design on freq. shifted filter scaled to -+1
% Returns a cascadeClass object
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

  [p, px, wp, ws, as, sclFctr, shftFctr] = nrmlzSpecsD(p, px, wp, ws, as);

  ONE_STP = 0;
  [H1, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,type);

  cscdFltr = proto2Cscd(H1, p, px, wp, ws, as, sclFctr, shftFctr);
  a=1;