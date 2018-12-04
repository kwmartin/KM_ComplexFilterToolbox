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

function [X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx(H, F, Porder, cmplxCoeffs)
  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  tol = 2e-6;
  if nargin < 3
      cmplxCoeffs = false;
  end
  [Ppl, Epl] = tfdata(H, 'v');
  if cmplxCoeffs == false
    Ppl = real(Ppl);
    Epl = real(Epl);
  end
  Fpl = poly(F);
  if cmplxCoeffs == false
    Fpl = real(Fpl);
  end
  Eevn = zipperEven(Epl);
  Eodd = zipperOdd(Epl);
  Fevn = zipperEven(Fpl);
  Fodd = zipperOdd(Fpl);
  [Eev, Eod] = getEvnOdd(Epl);
  [Fev, Fod] = getEvnOdd(Fpl);

  [P, E, ke] = zpkdata(H, 'v');
  Epl2 = polyClass(E, 1);
  Fpl2 = polyClass(F, 1);
  [Eev2, Eod2] = getEvnOddPly(Epl2);
  [Fev2, Fod2] = getEvnOddPly(Fpl2);

  if mod(Porder, 2) == 0, peven = 1; else peven = 0; end

  if (peven == 1)
    X1o = tf(reduceLeadTF(Eevn - Fevn), reduceLeadTF(Eodd + Fodd));
    X1s = tf(reduceLeadTF(Eodd - Fodd), reduceLeadTF(Eevn + Fevn));
    X2o = tf(reduceLeadTF(Eevn + Fevn), reduceLeadTF(Eodd + Fodd));
    X2s = tf(reduceLeadTF(Eodd - Fodd), reduceLeadTF(Eevn - Fevn));
  else
    X1o = tf(reduceLeadTF(Eodd - Fodd), reduceLeadTF(Eevn + Fevn));
    X1s = tf(reduceLeadTF(Eevn - Fevn), reduceLeadTF(Eodd + Fodd));
    X2o = tf(reduceLeadTF(Eodd + Fodd), reduceLeadTF(Eevn + Fevn));
    X2s = tf(reduceLeadTF(Eevn - Fevn), reduceLeadTF(Eodd - Fodd));
  end
  X1o = simpl(X1o, tol);
  X1s = simpl(X1s, tol);
  X2o = simpl(X2o, tol);
  X2s = simpl(X2s, tol);
  indic = 1;
  if (mxOrdr(X1s) > mxOrdr(X1o))
    [maxOrdr, nHigh] = mxOrdr(X1s);
    indic = 2;
  else
    [maxOrdr, nHigh] = mxOrdr(X1o);
    indic = 1;
  end
  if (mxOrdr(X2o) > maxOrdr)
    [maxOrdr, nHigh] = mxOrdr(X2o);
    indic = 3;
  end
  if (mxOrdr(X2s) > maxOrdr)
    [maxOrdr, nHigh] = mxOrdr(X2s);
    indic = 4;
  end
