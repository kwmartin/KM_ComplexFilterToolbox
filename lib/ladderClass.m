%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

classdef (ConstructOnLoad = true) ladderClass < handle
  % The ladderClass object ladderElems
  % It also has a function for evaluating the frequency response of
  % complex ladder filters
  properties
    ladderElems = ladderElem(0, 0, 0, 0, 'none');
    size = 0;
    I = 0 + 0j;
    V = 0 + 0j;
    R1 = 1;
    R2 = 1;
  end
  methods
    function obj = ladderClass(br)
      % obj.ladderElems(1) = ladderElem;
      if nargin == 0
        obj.size = 0;
      else
        if isa(br,'ladderClass')
          obj.ladderElems = br.ladderElems;
          obj.size = br.size;
          obj.I = br.I;
          obj.V = br.V;
          obj.R1 = br.R1;
          obj.R2 = br.R2;
        else
          obj.ladderElems(1).C = br.C;
          obj.ladderElems(1).L = br.L;
          obj.ladderElems(1).X = br.X;
          obj.ladderElems(1).Y = br.Y;
          obj.ladderElems(1).type = br.type;
          obj.size = 1;
        end
      end
    end
    function obj = addElem(obj, br)
      obj.size = obj.size + 1;
      obj.ladderElems(obj.size) = ladderElem(br.L, br.C, br.X, br.Y, br.type);
      I(obj.size) = 0 + 0j;
      V(obj.size) = 0 + 0j;
    end
    function obj = reverse(obj)
      obj.ladderElems = fliplr(obj.ladderElems);
      tmp = obj.R1;
      obj.R1 = obj.R2;
      obj.R2 = tmp;
    end
    function obj = makeSingleTerm(obj)
      obj.reverse();
      obj.R1 = 0;
      obj.R2 = 1;
    end

    function obj = freqScale(obj, scaleFctr)
    % frequency scale ladder; scaleFctr > 1 makes L's and C's smaller
    % all L's and C's are multiplied by 1/scaleFctr

      mltFctr = 1/scaleFctr;
      for i = 1:obj.size
        obj.ladderElems(i).L = mltFctr*obj.ladderElems(i).L;
        obj.ladderElems(i).C = mltFctr*obj.ladderElems(i).C;
      end
    end

    function obj = freqShft(obj, deltW)
    % frequency shifts a ladder up or down the j axis

      for i = 1:obj.size
        switch obj.ladderElems(i).type
          case 'SHC'
            obj.ladderElems(i).Y = obj.ladderElems(i).Y - deltW*obj.ladderElems(i).C*j;
          case 'SHL'
            obj.ladderElems(i).X = obj.ladderElems(i).X - deltW*obj.ladderElems(i).L*j;
          case 'SHLC'
            obj.ladderElems(i).X = obj.ladderElems(i).X - deltW*obj.ladderElems(i).L*j;
            obj.ladderElems(i).Y = obj.ladderElems(i).Y - deltW*obj.ladderElems(i).C*j;
          case 'SRC'
            obj.ladderElems(i).Y = obj.ladderElems(i).Y - deltW*obj.ladderElems(i).C*j;
          case 'SRL'
            obj.ladderElems(i).X = obj.ladderElems(i).X - deltW*obj.ladderElems(i).L*j;
          case 'SRLC'
            obj.ladderElems(i).X = obj.ladderElems(i).X - deltW*obj.ladderElems(i).L*j;
            obj.ladderElems(i).Y = obj.ladderElems(i).Y - deltW*obj.ladderElems(i).C*j;
        end
      end
    end

    function obj = impedScale(obj, scaleFctr)
    % frequency shifts a ladder up or down the j axis

      for i = 1:obj.size
        if abs(obj.ladderElems(i).Y) > 5*eps
          obj.ladderElems(i).Y = obj.ladderElems(i).Y/scaleFctr;
        end
        if abs(obj.ladderElems(i).C) > 5*eps
          obj.ladderElems(i).C = obj.ladderElems(i).C/scaleFctr;
        end
        if abs(obj.ladderElems(i).X) > 5*eps
          obj.ladderElems(i).X = obj.ladderElems(i).X*scaleFctr;
        end
        if abs(obj.ladderElems(i).L) > 5*eps
          obj.ladderElems(i).L = obj.ladderElems(i).L*scaleFctr;
        end
      end
      obj.R1 = obj.R1*scaleFctr;
      obj.R2 = obj.R2*scaleFctr;
    end

    % Evaluate ladder voltages and currents from output to input
    function [V0, I0] = freqEval(obj, w)
      obj.I = zeros(obj.size, length(w));
      obj.V = zeros(obj.size, length(w));
      for i=1:obj.size
        obj.ladderElems(i).I = zeros(1, length(w));
        obj.ladderElems(i).V = zeros(1, length(w));
      end
      % positive voltages and currents are left to right
      Vin = ones(1, length(w));
      Iin = Vin/obj.R2;
      for i=obj.size:-1:1
        obj.I(i, :) = Iin;
        obj.V(i, :) = Vin;
        if (strcmp(obj.ladderElems(i).type,'SHC') || strcmp(obj.ladderElems(i).type,'SHL') ...
            || strcmp(obj.ladderElems(i).type,'SHLC') || strcmp(obj.ladderElems(i).type,'SHX') ...
            || strcmp(obj.ladderElems(i).type,'SHY'))
          obj.ladderElems(i).V = obj.V(i, :);
          obj.I(i, :) = obj.I(i, :) + freqEval(obj.ladderElems(i), w);
        elseif (strcmp(obj.ladderElems(i).type,'SRC') || strcmp(obj.ladderElems(i).type,'SRL') ...
            || strcmp(obj.ladderElems(i).type,'SRLC') || strcmp(obj.ladderElems(i).type,'SRX') ...
            || strcmp(obj.ladderElems(i).type,'SRY'))
          obj.ladderElems(i).I = obj.I(i, :);
          obj.V(i, :) = obj.V(i, :) + freqEval(obj.ladderElems(i), w);
        end
        Iin = obj.I(i, :);
        Vin = obj.V(i, :);
      end
      V0 = obj.V(1, :) + obj.I(1, :)*obj.R1;
      I0 = obj.I(1, :);
    end
  end
end
