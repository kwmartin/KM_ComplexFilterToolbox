classdef  (ConstructOnLoad = true) pkBfrClass < handle
%   classdef  (ConstructOnLoad = true) pkBfrClass < handle implements a circular buffer
%   for containing previous peaks. The first peak in the buffer is 0 and contains index 0
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
    nmbPks = 64;
    minDelta = 0.0001;
    minProm = 0.3;
    minDiff = 12; % currently 156 BPM; needs to adapt
  end
  properties
    pkBfr = struct('indx', 0, 'yVal', 0, 'lDiff', 0, 'lVlly', inf, ...
      'rVlly', inf, 'rmvPk', false);
    pkPntr = 1;
    frstPntr = 0;
    lstIndx = 0;
    cpyRqrd = false;
    nmbSpurs = 0;
    avgSpur = 0;
    strBfr = [];
  end
  methods
    function pkBf = pkBfrClass(size)
      pkBf.pkBfr(size) = struct('indx', 0, 'yVal', 0, 'lDiff', 0, 'lVlly', inf, ...
        'rVlly', inf, 'rmvPk', false);
      pkBf.pkPntr = 1;
      pkBf.frstPntr = 0;
      pkBf.cpyRqrd = false;
      pkBf.nmbSpurs = 0;
      pkBf.avgSpur = 0;
    end

    function addPk(pkBf, indx, val, vlly)
      Mod = @(x,N)(mod(x - 1, N) + 1);
      % yindx = @(i,strt)(strt -1 + 1);

      N = pkBfrClass.nmbPks;
      ptr = pkBf.pkPntr;
      lstIndx = pkBf.lstIndx;
      pkBf.pkBfr(ptr).indx = indx;
      pkBf.pkBfr(ptr).yVal = val;
      pkBf.pkBfr(ptr).lVlly = vlly;
      pkBf.pkBfr(Mod(ptr - 1, N)).rVlly = vlly;
      pkBf.lstIndx = indx;
      if pkBf.frstPntr ~= 0
        pkBf.pkBfr(ptr).lDiff = indx - lstIndx;
        pkBf.pkBfr(ptr).rmvPk = false;
      else
        pkBf.frstPntr = 1;
      end
      % move ptr to next available peak
      ptr = Mod(ptr + 1, N);
      pkBf.pkPntr = ptr;
      % pkBf.pkBfr(ptr).indx = inf;
      if ptr == pkBf.frstPntr  pkBf.frstPntr = Mod(ptr + 1, N); end
    end
    
    function rmvPks(pkBf, datBfr, apprxPer)
      Mod = @(x,N)(mod(x - 1, N) + 1);
      N = pkBfrClass.nmbPks;
      Ndat = bufClass.nmbElems;
      frstPk = pkBf.frstPntr;
      lstIndx = pkBf.pkBfr(Mod(pkBf.pkPntr - 1, N)).indx;

      nmbPks = pkBf.pkPntr - frstPk;
      if nmbPks < 0 nmbPks = nmbPks + N; end
      pks = [];
      locs = [];
      for i = 0:nmbPks - 1
        indc = Mod(i + frstPk, N);
        pks = [pks, pkBf.pkBfr(indc).yVal];
        locs = [locs, pkBf.pkBfr(indc).indx];
      end
      rmIndcs = find((pks - mdFlt(pks)) < - 0.15);
      for indx = rmIndcs
        if indx == 1
          if abs(locs(2) - locs(1) - apprxPer) < 5 && pks(1) > 0.5
            rmIndcs(1) = [];
          end
        elseif indx == nmbPks
          if abs(locs(end) - locs(end-1) - apprxPer) < 5 && pks(end) > 0.5
            rmIndcs(end) = [];
          end
        else
          if (abs(locs(indx+1) - locs(indx) - apprxPer) < 5 || ...
              abs(locs(indx) - locs(indx - 1) - apprxPer) < 5) && pks(indx) > 0.5
            rmIndcs(rmIndcs == indx) = [];
          end
        end
          % check if peak should stay in
      end
      locs2 = locs;
      pks2 = pks;
      locs2(rmIndcs) = [];
      pks2(rmIndcs) = [];
      prblmIndcs = find(abs(diff(locs2) - apprxPer) > 4);
      if ~isempty(prblmIndcs)
        spurs = abs(diff(locs2) - apprxPer);
        nSprs = length(spurs);
        sprSum = sum(spurs);
        crntNtot =  pkBf.nmbSpurs;
        pkBf.nmbSpurs = pkBf.nmbSpurs + nSprs;
        pkBf.avgSpur = (crntNtot*pkBf.avgSpur + sprSum)/pkBf.nmbSpurs;
        % warning('periods are irregular');
      end
      a = 1;

    end
    
    function chkPrms(pkBf, datBfr, apprxPer)
      Mod = @(x,N)(mod(x - 1, N) + 1);
      N = pkBfrClass.nmbPks;
      Ndat = bufClass.nmbElems;
      frstPk = pkBf.frstPntr;
      lstIndx = pkBf.pkBfr(Mod(pkBf.pkPntr - 1, N)).indx;

      pkPtr = Mod(frstPk + 1, N);
      while pkBf.pkBfr(pkPtr).indx < lstIndx
        % if pk - lVlly < prominence and lPk > pk mark pk for removal
        pk =  pkBf.pkBfr(pkPtr).yVal;
        lVlly = pkBf.pkBfr(pkPtr).lVlly;
        lPk = pkBf.pkBfr(Mod(pkPtr - 1, N)).yVal;
        if (pk - lVlly) < pkBfrClass.minProm && lPk > pk
          pkBf.pkBfr(pkPtr).rmvPk = true;
        end
        if pkBf.pkBfr(pkPtr).lDiff < pkBfrClass.minDiff && lPk > pk
          pkBf.pkBfr(pkPtr).rmvPk = true;
        end

        % if pk - rVlly < prominence and rPk > pk mark pk for removal
        pk =  pkBf.pkBfr(pkPtr).yVal;
        rVlly = pkBf.pkBfr(pkPtr).rVlly;
        rPk = pkBf.pkBfr(Mod(pkPtr + 1, N)).yVal;
        if isempty(rPk)
          break;
        end
        if (pk - rVlly) < pkBfrClass.minProm && rPk > pk
          pkBf.pkBfr(pkPtr).rmvPk = true;
        end
        pkPtr = Mod(pkPtr + 1, N);
      end

      % go through peaks again and remove peaks marked for removal
      % fix left and right valleys and lDiff
      pkPtr = Mod(frstPk + 1, N);
      nxtPtr = Mod(pkPtr + 1, N);
      cpyPtr = pkPtr;
      while pkBf.pkBfr(pkPtr).indx < lstIndx
        lDiff = pkBf.pkBfr(pkPtr).lDiff;
        if pkBf.pkBfr(pkPtr).rmvPk
          pkBf.cpyRqrd = true;
          cpyNxt = true;
          vlly = min(pkBf.pkBfr(pkPtr).lVlly, pkBf.pkBfr(pkPtr).rVlly);
          lDiff = pkBf.pkBfr(pkPtr).lDiff + pkBf.pkBfr(nxtPtr).lDiff;
          % if more than one consecutive peak to remove (normally shouldn't happen)
          while pkBf.pkBfr(nxtPtr).rmvPk
            nxtPtr = Mod(nxtPtr + 1, N);
            vlly = min(vlly, pkBf.pkBfr(nxtPtr).lVlly);
            lDiff = lDiff + pkBf.pkBfr(nxtPtr).lDiff;
          end
          pkPtr = nxtPtr;
        else
          cpyNxt = false;
        end
        if pkBf.cpyRqrd
          if cpyNxt
            srcPtr = nxtPtr;
          else
            srcPtr = pkPtr;
          end
          % check in case we skipped to last peak
          if pkBf.pkBfr(srcPtr).indx >= lstIndx
            pkBf.pkBfr(srcPtr).lDiff = lDiff;
            break;
          end
          % replace peak to be removed with next valid peak
          pkBf.pkBfr(cpyPtr).yVal = pkBf.pkBfr(srcPtr).yVal;
          pkBf.pkBfr(cpyPtr).indx = pkBf.pkBfr(srcPtr).indx;
          pkBf.pkBfr(cpyPtr).rVlly = pkBf.pkBfr(srcPtr).rVlly;
          pkBf.pkBfr(cpyPtr).lVlly = pkBf.pkBfr(srcPtr).lVlly;
          pkBf.pkBfr(cpyPtr).lDiff = lDiff;
          pkBf.pkBfr(Mod(cpyPtr - 1, N)).rVlly = pkBf.pkBfr(cpyPtr).lVlly;
          pkBf.pkBfr(cpyPtr).rmvPk = false;
        end

        pkBf.strPk(pkBf.pkBfr(cpyPtr));

        cpyPtr = Mod(cpyPtr + 1, N);
        pkPtr = Mod(pkPtr + 1, N);
        nxtPtr = Mod(pkPtr + 1, N);
      end

      % add last peak back in
      pkBf.pkBfr(cpyPtr).yVal = pkBf.pkBfr(pkPtr).yVal;
      pkBf.pkBfr(cpyPtr).indx = pkBf.pkBfr(pkPtr).indx;
      pkBf.pkBfr(cpyPtr).rVlly = pkBf.pkBfr(pkPtr).rVlly;
      pkBf.pkBfr(cpyPtr).lVlly = pkBf.pkBfr(pkPtr).lVlly;
      pkBf.pkBfr(cpyPtr).lDiff = pkBf.pkBfr(pkPtr).lDiff;
      pkBf.pkBfr(cpyPtr).rmvPk = pkBf.pkBfr(pkPtr).rmvPk;
      % strPk(pkBf.pkBfr(cpyPtr));
      cpyPtr = Mod(cpyPtr + 1, N);
      pkBf.pkPntr = cpyPtr;
      a = 1;
    end

    function strPk(pkBf,pk)
      if isempty(pkBf.strBfr) || pk.indx > pkBf.strBfr(end).indx
        pkStr = struct('indx', pk.indx, 'val', pk.yVal,  'diff', pk.lDiff);
        if isempty(pkBf.strBfr)
          pkStr.diff = pkStr.indx';
        end
        pkBf.strBfr = [pkBf.strBfr, pkStr];
      end
      a = 1;
    end

    function diffs = getDiffs(pkBf)
      diffs = [];
      for i = 1:length(pkBf.strBfr)
          diffs = [diffs; pkBf.strBfr(i).diff];
      end
      a = 1;
    end

    function pks = getPks(pkBf)
      pks = [];
      for i = 1:length(pkBf.strBfr)
          pks = [pks; pkBf.strBfr(i).val];
      end
      a = 1;
    end

  end
end
