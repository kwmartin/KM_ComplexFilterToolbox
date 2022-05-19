classdef  (ConstructOnLoad = true) bufClass < handle
%   classdef  (ConstructOnLoad = true) bufClass < handle implements a circular buffer
%   used for caluculating autocorrelations
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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
  properties (Constant)
    nmbElems = 512;
    nmbLgs = 64;
    mxPk = 0.98;
  end
  properties
    bfr = zeros(1,512);
    ptr = 1;
    strt = 0;
    corrs = zeros(1,64);
    mnValue = inf;
    mxValue = 1.0;
    mxDiff = 0;
    pwrSq = 1;
    gain = 2.0;
    pkBf = pkBfrClass(1);
    nDatSmpls = 0;
  end
  methods
    function bf = bufClass(data)
      bf.bfr = data(:).';
      bf.pkBf = pkBfrClass(64);
      % if length(data) ~= bufClass.nmbElems
      %   error('Initial data must have 512 elements')
      % end
      N = bufClass.nmbElems;
      n = bufClass.nmbLgs;
      % bf.nmbElems = N;
      % bf.nmbLgs = n;
      if length(data) >= N
        bf.mxValue = max(data);
        data = (0.9/bf.mxValue).*data;
        for i = 0:n - 1
          indx1 = n + 1:N;
          indx2 = n + 1 - i:N - i;
          bf.corrs(i+1) = sum(data(indx1).*data(indx2));
        end
        
      end
      % bf.corrs(2:end) = bf.corrs(2:end)./bf.corrs(1); % nomalizes to power of corrs(1)
      bf.ptr = length(data) + 1;
      a = 1;
    end

    function corrs = updBfr(bf,indx,val)
      Mod = @(x,N)(mod(x - 1, N) + 1);
      bf.nDatSmpls = indx;
      val2 = val*bf.gain;
      if val2 > bufClass.mxPk
        bf.gain = bufClass.mxPk*(bf.gain/val2);
      end
      bf.pwrSq = (bf.pwrSq*(indx - 1) + val*val)/indx;
      if bf.pwrSq < 0.25
       bf.gain = bf.gain + 0.001;
       bf.mxValue = bufClass.mxPk;
      end
      if val2 > bf.mxValue bf.mxValue = val2; end
      N = bufClass.nmbElems;
      Ninv = 1/N;
      n = bufClass.nmbLgs;
      iptr = Mod(indx, N);
      bf.ptr = iptr;
      bf.strt = indx - iptr + 1;
      bf.bfr(iptr) = val2;
      % save minimum vallers in peak buffer
      if val2 < bf.mnValue
        bf.mnValue = val2;
      end

      % update peaks if necessary
      minDelt = pkBfrClass.minDelta;
      indx1 = Mod(iptr - 2, N);
      indx2 = Mod(iptr - 1, N);
      pkPt = bf.pkBf.pkPntr;
      if indx >= 3
        diff1 = bf.bfr(indx2) - bf.bfr(indx1);
        if diff1 > bf.mxDiff
           bf.mxDiff = diff1;
        end
        diff2 = bf.bfr(iptr) - bf.bfr(indx2);
        if bf.mxDiff > minDelt && diff2 < -minDelt
          bf.pkBf.addPk(indx - 1, bf.bfr(indx2), bf.mnValue);
          bf.mnValue = inf;
          bf.mxDiff =0;
        end
      end
      if indx == N
        bf.corrs = autoCorr(bf.bfr,1:n);
      end
      if indx > N
        % update autocorrelations
        indx0 = Mod(iptr - (N - n) + 1,N);
        indxs1 = indx0 - (0:n-1);
        indxs1 = Mod(indxs1,N);
        chngs1 = Ninv.*(bf.bfr(indx0).*bf.bfr(indxs1));
        corrs = bf.corrs - chngs1;
        indxs2 = iptr - (0:n-1);
        indxs2 = Mod(indxs2, N);
        chngs2 = Ninv.*(bf.bfr(iptr).*bf.bfr(indxs2));
        corrs = bf.corrs + chngs2;
        corrs = (1/corrs(1)).*corrs;
        bf.corrs = corrs;
      end
      corrs = bf.corrs;
    end
  end
end
