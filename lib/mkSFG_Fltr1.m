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

function [Fltr, Coeffs] = mkSFG_Fltr1(lddr)

  % Fltr = mkSFG_Fltr1(lddr) makes a system object assuming lddr is a filter with caps/jreacts only
  % the SFG is based on intregrators with capacitor feedins

  Coeffs = calcSFG_Fltr(lddr);
  sz = size(Coeffs);
  N = sz(1);
  for i = 1:N
    Nm = {[Coeffs(i,1), Coeffs(i,2)], [Coeffs(i,3), Coeffs(i,4)]};
    Dn = {[1, Coeffs(i,5)], [1, Coeffs(i,5)]};
    Tf = tf(Nm, Dn);
    Tf.y = sprintf('Out%d',i);
    Tf.u{1} = sprintf('Out%d',i-1);
    Tf.u{2} = sprintf('Out%d',i+1);
    TF{i} = Tf;
  end

  TF{N}.u{2}='Null';
  outNm = TF{N}.y{1};
  inNm =  {'Out0', 'Null'};

  Tf = connect(TF{:}, inNm, outNm);
  Fltr = simpl(zpk(Tf(1)));
