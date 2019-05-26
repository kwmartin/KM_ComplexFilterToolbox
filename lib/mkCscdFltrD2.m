function cscdFltr = mkCscdFltrD2(H, wp)
%   cscdFltr = mkCscdFltrD2(H, wp) designs a cascade filer given transfer function H
%   and passband wp. The object returned, cscdFltr, is a cascadeClass object.
%   cscdFltr is composed of 1st order sections only
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

  % Instantiate a cascadeClass object
  cscdFltr = cascadeClass();

  % order zeros and poles and combine zeros to closest poles starting
  % from zeros closest to passband and working out
  [z p] = groupZerosD(H, wp);
  nmbSctns = length(z);

  % Combine consecutive pairs of zeros and poles into zpk() systems
  % and add to cascadeClass() object

  for i=1:nmbSctns
    sys = zpk(z(i), p(i), 1, 1);
    sctn = cscFltrSctnClass(sys);
    sctn.setGain(1,wp);
    cscdFltr.addSctn(sctn);
  end

  for i = nmbSctns+1:length(p) % in case there are fewer poles than zeros
    sys = zpk([], p(i), 1, 1);
    sctn = cscFltrSctnClass(sys);
    sctn.setGain(1,wp);
    cscdFltr.addSctn(sctn);
  end

  % the built scaling function of the cascadeClass() is used to
  % scale peak gains to be unity (in the l-infinity sense)

  cscdFltr.scaleFltr(wp);
  a=1;
