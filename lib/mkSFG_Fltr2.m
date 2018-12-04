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

function [Fltr] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx)

  N = size(KfMtrx, 2);

  TOUT = tf(OutMtrx);

  for i = 1:N
    uCells{i} = sprintf('u%d', i);
    eCells{i} = sprintf('e%d', i);
    xCells{i} = sprintf('x%d', i);
    KfoCells{i} = sprintf('Kfo%d', i);
  end

  for i =1:size(KiMtrx, 2)
    xinCells{i} = sprintf('xin%d', i);
  end
  
  for i =1:size(OutMtrx, 1)
    oCells{i} = sprintf('o%d', i);
    dCells{i} = sprintf('d%d', i);
    outCells{i} = sprintf('out%d', i);
  end
  
  TOUT.u = xCells;
  TOUT.y = outCells;

  KF = tf(KfMtrx);

  KF.u = xCells;
  KF.y = KfoCells;

  KI = tf(KiMtrx);
  KI.u = xinCells;
  KI.y = uCells;

  Sm = sumblk('%e = %u + %Kfo', eCells, uCells, KfoCells);

  TF2 = {};
  for i = 1:N
    for j = 1:N
      if j == i
        Nm{j} = [1];
        Dn{j} = [1, 0];
      else
        Nm{j} = [0];
        Dn{j} = [1, 0];
      end
    end
    TF1 = tf(Nm, Dn);
    for j = 1:N
      TF1.u{j} = sprintf('x%d',j);
    end
    TF2{i} = TF1;
    TF2{i}.u = eCells;
    TF2{i}.y = xCells{i};
  end

  TF2{N+1} = KI;
  TF2{N+2} = KF;
  TF2{N+3} = TOUT;
  TF2{N+4} = Sm;
  outNm = outCells{N};
  warning('off','Control:combination:connect9')
  warning('off','Control:combination:connect10')
  TF3 = connect(TF2{:}, 'xin1', outNm);
  warning('on','Control:combination:connect9')
  warning('on','Control:combination:connect10')
  Fltr = simpl(zpk(TF3));
  
  a = 1;