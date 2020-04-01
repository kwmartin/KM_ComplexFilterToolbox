classdef (ConstructOnLoad = true) cascadeClass < handle
%   classdef (ConstructOnLoad = true) cascadeClass < handle
%   cascadeClass defines a class to hold Cascade Filter instantiations
%   The cascadeClass object contains biquads in cscFltrSctnClass objects
%   It also has a function for evaluating the frequency response of
%   complex cascade filters plus a number of other utility functions.
%   sctns: an array of cscFltrSctnClass objects which contain first or second order sections.
%   size: the number of sections
%   obj = cascadeClass(sctn): make a new cascadeClass object, sctn can be
%   empty, or a cascadeClass obj, for copying a filter, or cscFltrSctnClass which gets added as the first section
%   obj = addSctn(obj, sctn): add an additional section
%   gn = freqEval(obj, f): evaluate the cascade filter as frequencies f (in real Hz)
%   gn = scaleFltr(obj, wp): scale gains of sections so gain peaks are all 1 (f-inf scaling)
%   sys = getSystem(obj): update and return the overall system in a zpk system obj
%   sys = fshftFltr(obj, fshft): freq shift cascade filter; returns shifted zpk obj
%   sys = fsclFltr(obj, sclFctr): freq scale cascade filter using scaleFltrD.m
%   plotGn(obj, wp, ws, minY, maxY): plot the response of the cascade filter using plot_drsps.m
%   out = sim(obj, xin, delta_f): simulate the cascade filter for complex input signal xin, after optionally frequency shifting filter (useful for filterbanks)
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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
    sctns = cscFltrSctnClass(); % stores each biquad (or a first order section)
    size = 0; % the number of sections in the cascade filter
    sys = zpk([], [], 1); % is the complete system object
  end
  methods
    function obj = cascadeClass(sctn) % instatiate a new object
      if nargin == 0
        obj.size = 0; % return an empty object
      else
        if isa(sctn,'cascadeClass') % copy this cascade filter
          obj.sctns = sctn.sctns;
          obj.size = sctn.size;
        else
          obj.sctns(1).C = sctn; % a new object with the first section specified
          obj.size = 1;
        end
      end
    end

    % Add a section to cascade filter.
    function obj = addSctn(obj, sctn)
      obj.size = obj.size + 1;
      obj.sctns(obj.size) = cscFltrSctnClass(sctn);
      a=1;
    end

    % Evaluate cascade frequency response
    function gn = freqEval(obj, f)
      g = [];
      gprdct = ones(size(f));
      for i = 1:obj.size
        g(i) = obj.sctns(i).freqEval(f);
        gprdct = gprdct.*g(i);
      end
    end

    % scale gains of sections so gain peaks are all 1 (f-inf scaling)
    function gn = scaleFltr(obj, wp)
      wpExtend = 0.25*max(abs(wp));
      strt = wp(1) - wpExtend;
      stp = wp(2) + wpExtend;
      delta = (stp - strt)/10000;
      f = (strt:delta:stp).';

      gprdct = ones(size(f));
      for i = 1:obj.size
        g = obj.sctns(i).freqEval(f);
        gprdct = gprdct.*g;
        currentGn = max(abs(gprdct));
        gnChange = 1/currentGn;
        obj.sctns(i).setK(obj.sctns(i).k * gnChange);
        gprdct = gprdct*gnChange;
      end
      getSystem(obj); % update system
    end

    % update and return the overall system in a zpk system obj
    function sys = getSystem(obj)
      sys = zpk([], [], 1);
      for i = 1:obj.size
        sys = sys * obj.sctns(i).sys;
      end
      obj.sys = sys;
    end      

    % freq shift cascade filter; could be useful to track channels
    function sys = fshftFltr(obj, fshft)
      for i = 1:obj.size
        obj.sctns(i).sys = freq_shiftd(obj.sctns(i).sys, fshft);
      end
      sys = getSystem(obj);
    end      

    % freq scale cascade filter
    function sys = fsclFltr(obj, sclFctr)
      for i = 1:obj.size
        obj.sctns(i).sys = scaleFltrD(obj.sctns(i).sys, sclFctr);
      end
      sys = getSystem(obj);
    end      

    % update and return the overall system
    function plotGn(obj, wp, minY, maxY)
      % update system in case anything was changed
      obj.sys = getSystem(obj);
      plot_drsps(obj.sys, wp, 'b', [minY maxY]);
    end      

    function out = sim(obj, xin, delta_f)
      % simulate the possibly frequency shifted cascade filter
      xo = xin;
      for i = 1:obj.size
        xo = obj.sctns(i).sim(xo, delta_f);
      end
      out = xo;
    end

  end
end
