classdef (ConstructOnLoad = true) eqlzrDClass < handle
%   classdef (ConstructOnLoad = true) eqlzrDClass < handle
%   eqlzrDClass defines a cascade of discrete-time all-pass sections
%   (allPassDClass objects), used as a group-delay equalizer: it can be
%   cascaded onto an existing digital filter to adjust phase/group-delay
%   without changing the magnitude response.
%   sctns: an array of allPassDClass objects, one per section
%   size: the number of sections
%   T: the sample time shared by all sections (default 1)
%   sys: the complete cascaded system object, kept in sync via getSystem
%   obj = eqlzrDClass(arg, T): make a new equalizer with optional sample
%   time T (default 1); arg can be omitted (empty object), an eqlzrDClass
%   obj (copied), an allPassDClass obj (added as the first section), or a
%   numeric wi value or vector of wi values (one section built per
%   element).
%   obj = addSctn(obj, wi): add another all-pass section with parameter wi
%   sys = getSystem(obj): update and return the overall cascaded system
%   Hout = applyTo(obj, H): cascade the equalizer onto filter H, returning
%   H with its phase/group-delay adjusted and magnitude response unchanged
%   [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = analyze(obj, w): analyze the
%   composite equalizer at frequencies w (rad.) using AnlzDH.m
%   plotResponse(obj, frng, ymin, colour): plot magnitude/phase/group-delay
%   of the composite equalizer using plot_dam_ph_gd.m
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
    sctns = allPassDClass(); % stores each all-pass section
    size = 0; % the number of sections in the equalizer
    T = 1; % sample time shared by all sections
    sys = zpk([], [], 1, 1); % the complete cascaded system object
  end
  methods
    function obj = eqlzrDClass(arg, T) % instantiate a new object
      if nargin == 0
        obj.size = 0; % return an empty object
      else
        if nargin < 2
          T = 1;
        end
        obj.T = T;
        if isa(arg,'eqlzrDClass') % copy this equalizer
          obj.sctns = arg.sctns;
          obj.size = arg.size;
          obj.T = arg.T;
        elseif isa(arg,'allPassDClass') % a single section specified directly
          obj.sctns(1) = arg;
          obj.size = 1;
          obj.T = arg.T;
        else % numeric wi, or a vector of wi values -- one section per element
          wiVec = arg(:);
          for i = 1:length(wiVec)
            obj.sctns(i) = allPassDClass(wiVec(i), obj.T);
          end
          obj.size = length(wiVec);
        end
      end
    end

    % Add another all-pass section to the equalizer.
    function obj = addSctn(obj, wi)
      obj.size = obj.size + 1;
      obj.sctns(obj.size) = allPassDClass(wi, obj.T);
    end

    % update and return the overall cascaded system in a zpk system obj
    function sys = getSystem(obj)
      sys = zpk([], [], 1, obj.T);
      for i = 1:obj.size
        sys = sys * obj.sctns(i).sys;
      end
      obj.sys = sys;
    end

    % cascade the equalizer onto an existing filter H, returning the
    % combined system (magnitude response of H is unchanged)
    function Hout = applyTo(obj, H)
      obj.sys = getSystem(obj);
      Hout = mult_zpk(H, obj.sys);
    end

    % analyze the composite equalizer using AnlzDH.m
    function [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = analyze(obj, w)
      obj.sys = getSystem(obj);
      [lgH,phH,gdH,dLdW,dTdW,d2LdW,d2TdW] = AnlzDH(obj.sys, w);
    end

    % plot mag/phase/group-delay of the composite equalizer
    function plotResponse(obj, frng, ymin, colour)
      obj.sys = getSystem(obj);
      plot_dam_ph_gd(obj.sys, frng, ymin, colour);
    end

    function disp(obj) % display the equalizer's sections in a readable format
      if obj.size == 0
        disp('equalizer (discrete): no sections');
        return
      end
      lines = cell(obj.size, 1);
      for i = 1:obj.size
        wi = obj.sctns(i).wi;
        lines{i} = sprintf('  section %d: wi = %0.5g + %0.5gj', i, real(wi), imag(wi));
      end
      disp(sprintf('equalizer (discrete, T=%0.5g), %d section(s):', obj.T, obj.size));
      disp(strjoin(lines, sprintf('\n')));
    end
  end
end
