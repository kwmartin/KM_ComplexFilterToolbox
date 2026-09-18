classdef (ConstructOnLoad = true) allPassDClass < handle
%   classdef (ConstructOnLoad = true) allPassDClass < handle
%   allPassDClass defines a single first-order discrete-time all-pass
%   section, H(z) = (z^-1 - conj(wi))/(1 - wi*z^-1), where wi IS the pole
%   location directly and the zero is placed at its classical
%   conjugate-mirror 1/conj(wi). Rewritten in positive powers of z:
%   H(z) = -conj(wi)*(z - 1/conj(wi))/(z - wi), giving zero at 1/conj(wi),
%   pole at wi, and gain k = -conj(wi). wi may be complex; stability
%   requires abs(wi) < 1. This conjugate-based zero/pole mirroring gives
%   an exactly flat magnitude response |H(e^jw)| = 1 for ANY complex wi
%   (not just real wi): |k|/|wi| = |conj(wi)|/|wi| = 1 always, and the
%   frequency-dependent terms cancel exactly (verified algebraically) --
%   i.e. this genuinely adjusts phase/group-delay without changing
%   magnitude, which is the whole point of an equalizer. Used as a
%   building block for group-delay equalizers (see eqlzrDClass.m).
%   wi: the all-pass parameter, i.e. the pole location (complex scalar)
%   T: the sample time (default 1, matching this toolbox's convention)
%   sys: the zpk system object, kept in sync with wi and T
%   obj = allPassDClass(wi, T): make a new section with parameter wi and
%   optional sample time T (default 1); wi can be omitted (empty object),
%   a numeric scalar, or another allPassDClass object to copy.
%   obj = setWi(obj, wi): change wi and update the zpk model
%   [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = analyze(obj, w): analyze the
%   section at frequencies w (rad.) using AnlzDH.m
%   plotResponse(obj, frng, ymin, colour): plot magnitude/phase/group-delay
%   using plot_dam_ph_gd.m
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

  properties
    wi = [];
    T = 1;
    sys = zpk([], [], 1, 1);
  end
  methods
    function obj = allPassDClass(wi, T)
      if nargin == 0
        obj.wi = [];
        obj.T = 1;
        obj.sys = zpk([], [], 1, 1);
      else
        if isa(wi,'allPassDClass') % copy the current section
          obj.wi = wi.wi;
          obj.T = wi.T;
          obj.sys = wi.sys;
        else
          if nargin < 2
            T = 1;
          end
          obj.T = T;
          setWi(obj, wi);
        end
      end
    end

    function obj = setWi(obj, wi) % change wi (the pole) and update the zpk model
      warning('off', 'Control:ltiobject:TFComplex');
      warning('off', 'Control:ltiobject:ZPKComplex');
      if ~isa(wi,'double')
        error('wi must be double');
      end
      obj.wi = wi;
      obj.sys = zpk(1/conj(wi), wi, -conj(wi), obj.T);
      if abs(wi) >= 1
        warning('allPassDClass:unstablePole', ...
            'allPassDClass: pole at wi = %s has magnitude %0.5g >= 1 (need abs(wi) < 1)', ...
            num2str(wi), abs(wi));
      end
    end

    function [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = analyze(obj, w) % analyze using AnlzDH.m
      [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = AnlzDH(obj.sys, w);
    end

    function plotResponse(obj, frng, ymin, colour) % plot mag/phase/group-delay
      plot_dam_ph_gd(obj.sys, frng, ymin, colour);
    end

    function disp(obj) % display the section in a readable format
      outStr = sprintf('all-pass (discrete, T=%0.5g): wi = %0.5g + %0.5gj  (pole: wi, zero: 1/conj(wi))', ...
          obj.T, real(obj.wi), imag(obj.wi));
      disp(outStr);
    end
  end
end
