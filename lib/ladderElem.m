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

classdef ladderElem
  properties
    C=0;
    L=0;
    X=0.0j;
    Y=0.0j;
    I=0 + 0.0j;
    V=0 + 0.0j;
    type='none';
  end
  methods
    function obj = ladderElem(L, C, X, Y, type)
      if nargin == 0
        obj.C = 0;
        obj.L = 0;
        obj.X = 0;
        obj.Y = 0;
        obj.type = 'SHC';
      else
        obj.C = C;
        obj.L = L;
        obj.X = X;
        obj.Y = Y;
        obj.type = type;
        end
    end
    function r = freqEval(obj, w)
      switch obj.type
        case 'SHC'
          obj.I = (obj.V).*(obj.Y + 1./(obj.X + 1./(1.0j*w*obj.C)));
          r = obj.I;
        case 'SHL'
          obj.I = (obj.V)./(obj.X + 1./(obj.Y + 1./(1.0j*w*obj.L)));
          r = obj.I;
        case 'SHLC'
          obj.I = (obj.V)./((1.0j*w*obj.L + obj.X) + 1.0./(1.0j*w*obj.C + obj.Y));
          r = obj.I;
        case 'SHX'
          obj.I = (obj.V)./(obj.X);
          r = obj.I;
        case 'SHY'
          obj.I = (obj.V).*(obj.Y);
          r = obj.I;
        case 'SRC'
          obj.V = (obj.I)./(obj.Y + 1./(obj.X + 1./(1.0j*w*obj.C)));
          r = obj.V;
        case 'SRL'
          obj.V = (obj.I).*(obj.X + 1./(obj.Y + 1./(1.0j*w*obj.L)));
          r = obj.V;
        case 'SRLC'
          obj.V = (obj.I)./((1.0j*w*obj.C + obj.Y) + 1.0./(1.0j*w*obj.L + obj.X));
          r = obj.V;
        case 'SRX'
          obj.V = (obj.I).*(obj.X);
          r = obj.V;
        case 'SRY'
          obj.V = (obj.I)./(obj.Y);
          r = obj.V;
        end
    end
  end
end
