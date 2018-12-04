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

function cscdFltr = mkCscdFltr(H, wp, rvrsScl)
% makes a cascade filter from transfer function H

  cscdFltr = cascadeClass();
  [grps cnjPls cmplxPls] = groupZeros(H);
  for i = 1:length(cnjPls)
    z = [cnjPls{i}{1} conj(cnjPls{i}{1})];
    p = [cnjPls{i}{2} conj(cnjPls{i}{2})];
    k = 1;
    [H1, Ki1, KF1, Ko1, Kd1] = calcSectionSS(z, p, 1);
    Ki1 = Ki1*rvrsScl;
    KF1 = KF1*rvrsScl;
    [H2, Ki2, KF2, Ko2, Kd2] = calcSFG_DFltr(Ki1, KF1, Ko1, Kd1);
    sctn = cscFltrSctnClass(H2);
    sctn.setGain(1,wp);
    cscdFltr.addSctn(sctn);
  end
  for i = 1:length(cmplxPls)
    z = [cmplxPls{i}{1}];
    p = [cmplxPls{i}{2}];
    k = 1;
    [H1, Ki1, KF1, Ko1, Kd1] = calcSectionSS(z, p, 1);
    Ki1 = Ki1*rvrsScl;
    KF1 = KF1*rvrsScl;
    [H2, Ki2, KF2, Ko2, Kd2] = calcSFG_DFltr(Ki1, KF1, Ko1, Kd1);
    sctn = cscFltrSctnClass(H2);
    sctn.setGain(1,wp);
    cscdFltr.addSctn(sctn);
  end
  cscdFltr.scaleFltr(wp);
  a=1;
