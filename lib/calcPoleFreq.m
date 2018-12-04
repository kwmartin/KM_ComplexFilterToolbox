function r = calcPoleFreq(elem)
%   calculates the loss pole frequency of ladder component 'elem'
%   At 11/2018, I don't think this function is being used, but need to check
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
      switch obj.type
        case 'SHC'
          obj.I = obj.V.*(1.0j*w*obj.C + obj.Y);
          r = obj.I;
        case 'SHL'
          obj.I = obj.V./(1.0j*w*obj.L + obj.X);
          r = obj.I;
        case 'SHLC'
          obj.I = obj.V./((1.0j*w*obj.L + obj.X) + 1.0./(1.0j*w*obj.C + obj.Y));
          r = obj.I;
        case 'SHX'
          obj.I = obj.V./(obj.X);
          r = obj.I;
        case 'SHY'
          obj.I = obj.V.*(obj.Y);
          r = obj.I;
        case 'SRC'
          obj.V = obj.I./(1.0j*w*obj.C + obj.Y);
          r = obj.V;
        case 'SRL'
          obj.V = obj.I.*(1.0j*w*obj.L + obj.X);
          r = obj.V;
        case 'SRLC'
          obj.V = obj.I./((1.0j*w*obj.C + obj.Y) + 1.0./(1.0j*w*obj.L + obj.X));
          r = obj.V;
        case 'SRX'
          obj.V = obj.I.*(obj.X);
          r = obj.V;
        case 'SRY'
          obj.V = obj.I./(obj.Y);
          r = obj.V;
        end
