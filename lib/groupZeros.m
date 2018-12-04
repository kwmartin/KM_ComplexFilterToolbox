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

function [grps cnjPls cmplxPls] = groupZeros(H)
% groupZeros() is used to pair the zeros of a continuous time transfer function with poles
%

  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  tol = 1e-4;
  grps = {};
  [z,p,k] = zpkdata(H, 'v');
  nz = length(z);
  np = length(p);

  % sort poles and zeros in ascending order based on imaginary parts

  z2 = sortRootsD(z);
  p2 = sortRootsD(p);

  % save for later use in finding conjugate pairs
  z3 = z2;
  p3 = p2;

  % group zeros to closest poles
  i = 1;
  while length(z2) ~=0
    imagZ = imag(z2(1));
    [closeP indx] = min(abs(imag(p2) - imagZ));
    grps{i} = {z2(1), p2(indx)};
    p2(indx) = [];
    z2(1) = [];
    i = i+1;
  end

  % add grps for remaining poles having zeros at infinity
  for i=1:length(p2)
    grps{i+nz} = {[], p2(i)};
  end

  % find conjugate zero,pole groups
  cnjPls = {};
  cmplxPls = {};
  cnjIndx = 1;
  cmplxIndx = 1;
  i = 1;
  while length(p3) ~=0
    pl = p3(1);
    for i = 1:length(grps)
      if grps{i}{2} == pl
        zr = grps{i}{1};
        break;
      end
    end
    if (abs(imag(pl)) > tol) && (any(find(abs(conj(pl) - p3) < tol)))
      cnjPls{cnjIndx} = {zr, pl};
      Indx = find(abs(conj(pl) - p3) < tol);
      p3(Indx) = [];
      p3(1) = [];
      cnjIndx = cnjIndx+1;
    else
      cmplxPls{cmplxIndx} = {zr, pl};
      p3(1) = [];
      cmplxIndx = cmplxIndx+1;
    end
    i = i+1;
  end

  a=1;
