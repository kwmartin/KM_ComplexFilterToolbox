function [X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx(H, F, Porder, cmplxCoeffs)
%   [X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx(H, F, Porder, cmplxCoeffs) finds 2-port reactances
%   H is transfer function used to get P (loss poles) and E (transfer function poles)
%   Porder is the number of loss-poles, cmplxCoeffs = 1 if there is not complex-conjugate
%   symmetry. This function uses the class object polyClass to help improve robustness
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

  global imagRoots;
  warning('off', 'Control:ltiobject:TFComplex');
  warning('off', 'Control:ltiobject:ZPKComplex');

  tol = 2e-6;
  imagRoots = 0;

  if nargin < 3
      cmplxCoeffs = false;
  end

  [P, E, ke] = zpkdata(H, 'v');

  Epl = polyClass(E, 1);
  Fpl = polyClass(F, 1);
  [Eev, Eod] = getEvnOddPly(Epl);
  [Fev, Fod] = getEvnOddPly(Fpl);

  if mod(Porder, 2) == 0, peven = 1; else peven = 0; end

  imagRoots = 1;
  if (peven == 1)
    X1oN = Eev - Fev;
    X1oD = Eod + Fod;
    X1o = zpk(X1oN.rts, X1oD.rts, X1oN.K/X1oD.K);

    X1sN = Eod - Fod;
    X1sD = Eev + Fev;
    X1s = zpk(X1sN.rts, X1sD.rts, X1sN.K/X1sD.K);

    X2oN = Eev + Fev;
    X2oD = Eod + Fod;
    X2o = zpk(X2oN.rts, X2oD.rts, X2oN.K/X2oD.K);

    X2sN = Eod - Fod;
    X2sD = Eev - Fev;
    X2s = zpk(X2sN.rts, X2sD.rts, X2sN.K/X2sD.K);
  else
    X1oN = Eod - Fod;
    X1oD = Eev + Fev;
    X1o = zpk(X1oN.rts, X1oD.rts, X1oN.K/X1oD.K);

    X1sN = Eev - Fev;
    X1sD = Eod + Fod;
    X1s = zpk(X1sN.rts, X1sD.rts, X1sN.K/X1sD.K);

    X2oN = Eod + Fod;
    X2oD = Eev + Fev;
    X2o = zpk(X2oN.rts, X2oD.rts, X2oN.K/X2oD.K);

    X2sN = Eev - Fev;
    X2sD = Eod - Fod;
    X2s = zpk(X2sN.rts, X2sD.rts, X2sN.K/X2sD.K);
  end
  imagRoots = 0;

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
