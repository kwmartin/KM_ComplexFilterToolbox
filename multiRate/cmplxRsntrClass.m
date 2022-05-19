classdef (ConstructOnLoad = true) cmplxRsntrClass < handle
% The cmplxRsntrClass is a class for an infinite-Q digital resonator suitable
% for a resonator-in-a-loop filter
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
    fp = 1/16.0;
    wi = 2*pi/16;
    zp = exp(1j*2*pi/16);
    Xi = 0;
    X = 0;
    Xo = 0;
    N = 64;
  end

  methods
    function obj = cmplxRsntrClass(wi, Xinit, N)
      if nargin == 0
        obj.wi = 2*pi/16;
        obj.zp = exp(1j*2*pi/16);
        obj.X = 0;
        obj.N = 64;
        Xi = 0;
        Xo = 0;
      elseif nargin == 1
        obj.wi = wi;
        obj.zp = exp(1j*obj.wi);
        obj.X = 0;
        obj.N = 64;
        Xi = 0;
        Xo = 0;
        a = 1;
      elseif nargin == 3
        obj.wi = wi;
        obj.zp = exp(1j*obj.wi);
        obj.X = Xinit;
        obj.N = N;
        Xi = 0;
        obj.Xo = obj.zp .* obj.X;
        a = 1;
      else % return a new object that realizes systemp zpk object
        if (nargin ~= 1) or (nargin ~= 2)
          error('resonatorClass() should be called with 1 or 2 arguments: nargin: %d', nargin);
        end
      end
    end

    function obj = setWi(obj, wi) % change to a new zpk object and update sub-components
      obj.wi = wi;
      obj.zp = exp(1j*wi);
    end

    function [X1, X2] = setState(obj, Xset) % Initialize States
      obj.X = Xset;
      a = 1;
    end

    function Xo = updateState(obj, xin) % Initialize States
      obj.Xi = xin + obj.zp .* obj.X;
      obj.X = obj.Xi;
      obj.Xo = obj.zp .* obj.X;
    end

    function disp(obj) % display the section in a readable format
      outStr = sprintf('wi: %0.5g, zp: %0.5g + %0.5gj, N: %u\n', ...
          obj.wi, real(obj.zp), imag(obj.zp), obj.N);
      disp(outStr);
    end
  end
end