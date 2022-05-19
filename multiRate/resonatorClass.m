classdef (ConstructOnLoad = true) resonatorClass < handle
% The resonatorClass is a class for an infinite-Q digital resonator suitable
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
    k= 0.390180;
    Xfb = 1.0;
    Xs = 0.0;
    X2i = 0.0;
    X1 = 0.0;
    X2 = 0.0;
    X1i = 0.0;
  end

  methods
    function obj = resonatorClass(k, X10, X20)
      if nargin == 0
        obj.k = 0.390180;
        obj.X1 = 0.0;
        obj.X2 = 1.0;
        obj.X2i = obj.k * obj.X1 + obj.X2;
        obj.Xfb = 2 * obj.X1 - obj.k * obj.X2i;
        obj.Xs = 2 * obj.X2i;
        obj.X1i = obj.k * obj.X2i + obj.X1;
      elseif nargin == 3
        N = size(k, 2);
        %  obj(1,N) = obj;
        %  for i = 1:N
        %    obj(i).k = k(i);
        %    obj(i).X1 = X10(i);
        %    obj(i).X2 = X20(i);
        %  end
        obj.k = k;
        obj.X1 = X10;
        obj.X2 = X20;
        obj.X2i = obj.k * obj.X1 + obj.X2;
        obj.Xfb = 2 * obj.X1 - obj.k * obj.X2i;
        obj.X1i = obj.k * obj.X2i + obj.X1;
        a = 1;
      else % return a new object that realizes systemp zpk object
        if nargin ~= 1
          error('resonatorClass() should be called with 1 or 3 arguments: nargin: %d', nargin);
        end
      end
    end

    function obj = setK(obj, k) % change to a new zpk object and update sub-components
      obj.k = ks;
    end

    function [X1, X2] = getInitState(obj, Xfb, Xs) % Initialize States
      x2i = Xs ./ 2;
      X1 = Xfb + obj.k * x2i / 2;
      X2 = x2i - obj.k * obj.X1;
      a = 1;
    end

    function [X1, X2] = updateState(obj, xin) % Initialize States
      obj.X2i = obj.k * obj.X1 + obj.X2;
      obj.Xs = 2 * obj.X2i;
      obj.X1i = xin - obj.k * obj.X2i + obj.X1;
      obj.X1 = obj.X1i;
      obj.X2 = obj.X2i;
      obj.Xfb = 2 * obj.X1 - obj.k * obj.X2i;
    end

    function disp(obj) % display the section in a readable format
      outStr = sprintf('k: %0.5g, X1: %0.5g, X2: %0.5g\n', obj.k, obj.X1, obj.X2);
      disp(outStr);
      outStr = sprintf('Xfb: %0.5g, Xs: %0.5g\n', obj.Xfb, obj.Xs);
      disp(outStr);
    end
  end
end