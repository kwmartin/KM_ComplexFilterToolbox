function Fltr = calcSFG1(lddr) % used to generate transfer function
%   used in SFG analog simulation
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

  % 3 capacitors for two loss poles plus one loss pole at infinity
  NmbElems = lddr.size;
  N = 2*(NmbElems -1)/3 + 1;
  if mod(N, 2) == 0
    error('The filter order must be odd to make a digital SFG');
  end

  for i = 1:N
    v1Cells{i} = sprintf('v1_%d', i);
    v2Cells{i} = sprintf('v2_%d', i);
    v3Cells{i} = sprintf('v3_%d', i);
    x1Cells{i} = sprintf('x1_%d', i);
    x2Cells{i} = sprintf('x2_%d', i);
    x3Cells{i} = sprintf('x3_%d', i);
  end

  elem0 = ladderElem(0, 0, 0, 0, 'SHC');
  elems = lddr.ladderElems;

  s = tf('s');
  Coeffs=[];
  Coeffs(1, :) = calcSFG_Coeffs(elem0, elems(1), elems(2), 1/lddr.R1, 1/lddr.R1);
  TF2 = {};
  TF2{1} = [s*(Coeffs(1,2) - Coeffs(1,1)*Coeffs(1,5))/(s + Coeffs(1,5)), ...
  s*(Coeffs(1,4) - Coeffs(1,3)*Coeffs(1,5))/(s + Coeffs(1,5)); ...
  (Coeffs(1,2) + s*Coeffs(1,1))/(s + Coeffs(1,5)), ...
 (Coeffs(1,4) + s*Coeffs(1,3))/(s + Coeffs(1,5))];
  TF2{1}.u = {'vin', 'x3_2'};
  TF2{1}.y = {'x1_1', 'x3_1'};

  Coeffs(N, :) = calcSFG_Coeffs(elems(NmbElems - 1), elems(NmbElems), elem0, 0, 1/lddr.R2);
  TF2{N} = [s*(Coeffs(N,2) - Coeffs(N,1)*Coeffs(N,5))/(s + Coeffs(N,5)), ...
  s*(Coeffs(N,4) - Coeffs(N,3)*Coeffs(N,5))/(s + Coeffs(N,5)); ...
  (Coeffs(N,2) + s*Coeffs(N,1))/(s + Coeffs(N,5)), ...
 (Coeffs(N,4) + s*Coeffs(N,3))/(s + Coeffs(N,5))];
  TF2{N}.u = {x3Cells{N-1}, 'null'};
  TF2{N}.y = {x1Cells{N}, x3Cells{N}};

  elemNmb = 2;
  for i = 2:(N - 1)
    if mod(i, 2) == 0
      Coeffs(i, :) = calcSFG_Coeffs(elems(elemNmb), elem0, elems(elemNmb + 1), 0, 0); % shunt element is 0
      elemNmb = elemNmb + 1;
    else
      Coeffs(i, :) = calcSFG_Coeffs(elems(elemNmb), elems(elemNmb + 1), elems(elemNmb + 2), 0, 0);
      elemNmb = elemNmb + 2;
    end
    TF2{i} = [s*(Coeffs(i,2) - Coeffs(i,1)*Coeffs(i,5))/(s + Coeffs(i,5)), ...
    s*(Coeffs(i,4) - Coeffs(i,3)*Coeffs(i,5))/(s + Coeffs(i,5)); ...
    (Coeffs(i,2) + s*Coeffs(i,1))/(s + Coeffs(i,5)), ...
    (Coeffs(i,4) + s*Coeffs(i,3))/(s + Coeffs(i,5))];
    TF2{i}.u = {x3Cells{i-1}, x3Cells{i+1}};
    TF2{i}.y = {x1Cells{i}, x3Cells{i}};
  end

  outNm = x3Cells{N};
  warning('off','Control:combination:connect9')
  warning('off','Control:combination:connect10')
  TF3 = connect(TF2{:}, 'vin', outNm);
  warning('on','Control:combination:connect9')
  warning('on','Control:combination:connect10')
  Fltr = simpl(zpk(TF3), 2e-6);
  Fltr = minreal(Fltr, 2e-6);
  
  a=1;
