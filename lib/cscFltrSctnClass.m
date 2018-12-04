classdef (ConstructOnLoad = true) cscFltrSctnClass < handle
% The cscFltrSctnClass is a class for a section or biquad of a digital cascade filter
% Normally, the sections are second order, but first order sections are also supported
% The section is stored as a zpk model and also as zeros, poles, and k factor for easy
% access and changes. Whenever any sub components are changed, the zpk model is updated
% Their are number of utility functions such as frequency analysis, difference-equation
% simulation, etc. (see documentation below)
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
  properties
    z = [];
    p = [];
    k = 0;
    n = 0;
    T = 1;
    sys = zpk([], [], 1);
    type = 'frstOrdr'
  end
  methods
    function obj = cscFltrSctnClass(sys)
      if nargin == 0
        obj.z = [];
        obj.p = [];
        obj.k = 0;
        obj.n = 0;
      else
        if isa(sys,'cscFltrSctnClass') % copy the current section
          obj.sys = sys.sys;
          [z p k T] = zpkdata(sys.sys, 'v');
          obj.z = z;
          obj.p = p;
          obj.k = k;
          obj.n = length(p);
        else % return a new object that realizes systemp zpk object
          if nargin ~= 1
            error('cscFltrSctnClass() should be called with 1 argument: nargin: %d', nargin);
          end
          obj.sys = sys;
          [z p k T] = zpkdata(sys, 'v');
          obj.z = sortRoots(z);
          obj.p = sortRoots(p);
          obj.n = length(p);
          obj.k = k;
          obj.T = T;
         end
      end
    end

    function obj = setSys(obj, sys) % change to a new zpk object and update sub-components
      obj.sys = sys;
      [z p k T] = zpkdata(sys, 'v');
      obj.z = sortRoots(z); % zeros and poles are stored in sorted order based on imag parts
      obj.p = sortRoots(p);
      obj.n = length(p);
      obj.k = k;
      obj.T = T;
    end

    function obj = setZ(obj, z) % change to new zeros and update
      if ~isa(z,'double')
        error('Zeros must be double');
      end
      obj.z = z(:).';
      obj.z = sortRoots(obj.z);
      obj.sys = zpk(obj.z, obj.p, obj.k, obj.T);
    end

    function obj = setP(obj, p) % change to new poles and update
      if ~isa(p,'double')
        error('Poles must be double');
      end
      obj.p = p(:).';
      obj.p = sortRoots(obj.p);
      obj.n = length(obj.n);
      obj.sys = zpk(obj.z, obj.p, obj.k, obj.T);
    end

    function obj = setK(obj, k) % change to a new gain constant and update
      if ~isa(k,'double')
        error('k must be double');
      end
      obj.k = k;
      obj.sys = zpk(obj.z, obj.p, obj.k, obj.T);
    end

    function mxGn = getGain(obj, wp) % return the maximum absolute gain
      % wp specifies the frequencies that will be evaluated to find the maximum
      wpExtend = 0.25*max(abs(wp));
      strt = wp(1) - wpExtend;
      stp = wp(2) + wpExtend;
      delta = (stp - strt)/10000;
      f = strt:delta:stp;
      hm = abs(freqEval(obj, f));
      mxGn = max(hm);
    end

    function obj = setGain(obj, gain, wp) % set the maximum absolute gain
      currentGn = getGain(obj, wp);
      obj.k = obj.k*(gain/currentGn);
      obj.sys = zpk(obj.z, obj.p, obj.k, obj.T);
    end

    function gn = freqEval(obj, f) % evaluate the frequency response
      % evaluate the complex gain of the section at frequencies f (Hz)
      obj.sys = zpk(obj.z, obj.p, obj.k, obj.T); % make sure obj.sys is up to date
      [zd pd kd] = zpkdata(obj.sys, 'v');
      b = poly(zd);
      a = poly(pd);
      s = 2*pi*f; % convert to rad.
      gn=kd.*freqz(b,a,s);
      gn = gn(:); % return a column vector of complex gains
    end

    function out = sim(obj, xin, delta_f) % simulate the section
      % xin is the input data. delta_f is normally zero, but the
      % section can be optionally frequency shifted to support tunable
      % pass-bands. The difference equations used for simulation are
      % based on the state-space formulation

      [a b c d] = ssdata(obj.sys);
      eshft = exp(j*2*pi*delta_f);
      npts = length(xin);
      out = zeros(npts, 1);
      N = size(a,1);
      X = zeros(N, 1);
      for i = 1:npts
        out(i) = c*X + d*xin(i);
        X1 = a*X + b*xin(i);
        X = X1*eshft;
      end
    end

    function disp(obj) % display the section in a readable format
      nz = length(obj.z);
      if nz == 0
        zStr = '[]';
      elseif nz == 1
        zStr = sprintf('%0.5g + %0.5gj', obj.z(1), imag(obj.z(1)));
      else
        zStr = sprintf('%0.5g + %0.5gj, %0.5g + %0.5gj', ...
            obj.z(1), imag(obj.z(1)), obj.z(2), imag(obj.z(2)));
      end
      np = length(obj.p);
      if np == 0
        pStr = '[]';
      elseif np == 1
        pStr = sprintf('%0.5g + %0.5gj', obj.p(1), imag(obj.p(1)));
      else
        pStr = sprintf('%0.5g + %0.5gj, %0.5g + %0.5gj', ...
            obj.p(1), imag(obj.p(1)), obj.p(2), imag(obj.p(2)));
      end
      outStr = sprintf('z: %s\np: %s\nk: %d, n: %d', zStr, pStr, obj.k, obj.n);
      disp(outStr);
    end
  end
end
