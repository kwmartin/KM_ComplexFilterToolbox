classdef (ConstructOnLoad = true) allPassClass < handle
%   classdef (ConstructOnLoad = true) allPassClass < handle
%   allPassClass defines a single first-order continuous-time all-pass
%   section, H(s) = (s + conj(wi))/(s - wi), where wi IS the pole
%   location directly and the zero is placed at its classical
%   conjugate-mirror -conj(wi). wi may be complex; stability requires
%   real(wi) < 0. This conjugate-based zero/pole mirroring gives an
%   exactly flat magnitude response |H(jw)| = 1 for ANY complex wi (not
%   just real wi), verified via |jw+conj(wi)| = |jw-wi| for all real w --
%   i.e. this genuinely adjusts phase/group-delay without changing
%   magnitude, which is the whole point of an equalizer. Used as a
%   building block for group-delay equalizers (see eqlzrClass.m).
%   wi: the all-pass parameter, i.e. the pole location (complex scalar)
%   sys: the zpk system object, kept in sync with wi
%   obj = allPassClass(wi): make a new section with parameter wi; wi can
%   be omitted (empty object), a numeric scalar, or another allPassClass
%   object to copy.
%   obj = setWi(obj, wi): change wi and update the zpk model
%   [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = analyze(obj, w): analyze the
%   section at frequencies w (rad./s) using AnlzH.m
%   plotResponse(obj, wp, colour): plot magnitude/phase/group-delay using
%   plot_am_ph_gd.m
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
    sys = zpk([], [], 1);
  end
  methods
    function obj = allPassClass(wi)
      if nargin == 0
        obj.wi = [];
        obj.sys = zpk([], [], 1);
      else
        if isa(wi,'allPassClass') % copy the current section
          obj.wi = wi.wi;
          obj.sys = wi.sys;
        else
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
      obj.sys = zpk(-conj(wi), wi, 1);
      if real(wi) >= 0
        warning('allPassClass:unstablePole', ...
            'allPassClass: pole at wi = %s is not strictly stable (need real(wi) < 0)', num2str(wi));
      end
    end

    function [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = analyze(obj, w) % analyze using AnlzH.m
      [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = AnlzH(obj.sys, w);
    end

    function plotResponse(obj, wp, colour) % plot mag/phase/group-delay
      plot_am_ph_gd(obj.sys, wp, colour);
    end

    function disp(obj) % display the section in a readable format
      outStr = sprintf('all-pass (continuous): wi = %0.5g + %0.5gj  (pole: wi, zero: -conj(wi))', ...
          real(obj.wi), imag(obj.wi));
      disp(outStr);
    end
  end
end
