function cscdFltr = mkCscdFltrD(H, wp)
%   cscdFltr = mkCscdFltrD(H, wp) designs a cascade filer given transfer function H
%   and passband wp. The object returned, cscdFltr, is a cascadeClass object.
%   cscdFltr is composed of 2nd order functions having two complex zeros and two
%   complex poles. Possibly, there will also be a first-order section although this
%   does not occur when the bilinear-z transform method is used
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
  nmbBqds = floor(length(p)/2);

  % Combine consecutive pairs of zeros and poles into zpk() systems
  % and add to cascadeClass() object

  for i=1:nmbBqds
    zsctn = [z(2*i - 1) z(2*i)];
    psctn = [p(2*i - 1) p(2*i)];
    sys = zpk(zsctn, psctn, 1, 1);
    sctn = cscFltrSctnClass(sys);
    sctn.setGain(1,wp);
    cscdFltr.addSctn(sctn);
  end

  % Added for completeness, for digital filters based on the binlinear-z
  % transform, the order is always even

  if 2*nmbBqds ~= length(p) % the order is odd, add a first order
    zsctn = [z(end)];
    psctn = [p(end)];
    sys = zpk(zsctn, psctn, 1, 1);
    sctn = cscFltrSctnClass(sys);
    sctn.setGain(1,wp);
    cscdFltr.addSctn(sctn);
  end

  % the built scaling function of the cascadeClass() is used to
  % scale peak gains to be unity (in the l-infinity sense)

  cscdFltr.scaleFltr(wp);
  a=1;
