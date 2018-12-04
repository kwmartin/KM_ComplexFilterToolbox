function SS = findNodeTF(elem1, elem2, elem3)
%   SS = findNodeTF(elem1, elem2, elem3, GS, GL) finds the transfer function at ladder
%   node where elem2 is a shunt component and then converts it to a discrete SS
%   model using the bilinear transfer function
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

  s = tf('s');

  switch elem1.type
    case 'SRC'
      Y1 = s*elem1.C + elem1.Y;
    case 'SRL'
      Y1 = 1/(s*elem1.L + elem1.X);
    case 'SRLC'
      Y1 = 1/(s*elem1.C  + elem1.Y + 1/(s*elem1.L + elem1.X));
    case 'SRY'
      Y1 = elem1.Y;
    case 'SRX'
      Y1 = 1/(elem1.X);
    otherwise
      error('The first element must be a series element or Rs');
  end

  switch elem2.type
    case 'SHC'
      Y2 = s*elem2.C + elem2.Y;
    case 'SHL'
      Y2 = 1/(s*elem2.L + elem2.X);
    case 'SHLC'
      Y2 = 1/(s*elem2.C  + elem2.Y + 1/(s*elem2.L + elem2.X));
    case 'SHY'
      Y2 = elem2.Y;
    case 'SHX'
      Y2 = 1/(elem2.X);
    otherwise
      error('The second element must be shunt');
  end

  switch elem3.type
    case 'SRC'
      Y3 = s*elem3.C + elem3.Y;
    case 'SRL'
      Y3 = 1/(s*elem3.L + elem3.X);
    case 'SRLC'
      Y3 = 1/(s*elem3.C  + elem3.Y + 1/(s*elem3.L + elem3.X));
    case 'SRY'
      Y3 = elem3.Y;
    case 'SRX'
      Y3 = 1/(elem3.X);
    otherwise
      error('The third element must be a series element');
  end

  Den = Y1 + Y2 + Y3;
  TF = [Y1/Den, Y3/Den];

  % The bilinear function in the Control toolbox does not work with complex
  % systems; however, the bilinear function in the signal processing toolbox
  % works for complex transfer functions

  % Extract zeros, poles, and k
  [z1 p1 k1] = zpkdata(TF(1), 'v');
  % Transform to discrete-time system using bilinear transform
  [zd1 pd1 kd1] = bilinear(z1,p1,k1,1);

  % Make control-system zpk model
  TF1 = zpk(zd1,pd1,kd1,1);

  % Extract zeros, poles, and k
  [z2 p2 k2] = zpkdata(TF(2), 'v');
  % Transform to discrete-time system using bilinear transform
  [zd2 pd2 kd2] = bilinear(z2,p2,k2,1);

  % Make control-system zpk model
  TF2 = zpk(zd2,pd2,kd2,1);

  SS = ss([TF1, TF2]);

  a=1; % for debug break point