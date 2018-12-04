classdef (ConstructOnLoad = true) polyClass < handle
%   The polyClass object supports polynomial operations in "zero" form
%   without reverting back to transfer function form. It does this largely
%   by adding or subtracting other polyClass objects by using root finding
%   The root uses Muller with deflation to get close and then finishes with
%   root polishing using Newton-Raphson.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2018  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%
%classdef (ConstructOnLoad = true) polyClass < matlab.mixin.Copyable

  properties
    rts = [];
    N = 0;
    K = 0;
  end
  methods
    function obj = polyClass(rts, k)
      if nargin == 0
        obj.rts = [];
        obj.N = 0;
        obj.K = 0;
      else
        if isa(rts,'polyClass')
          obj.rts = rts.rts;
          obj.N = rts.N;
          obj.K = rts.K;
        else
          rts = rts(:).';
          obj.rts = sortRoots(rts);
          obj.cleanRts();
          obj.rts = obj.rts(:);
          obj.N = length(rts);
          obj.K = k;
        end
      end
    end
    function obj = set.rts(obj, rts)
      if ~isa(rts,'double')
        error('Poles must be double');
      end
      obj.rts = rts(:);
      obj.rts = sortRoots(obj.rts);
      obj.N = length(obj.rts);
    end

    function obj = set.K(obj, k)
      if ~isa(k,'double')
        error('K must be double');
      end
      obj.K = k;
    end

    function obj = addRoot(obj, P)
      obj.rts = [obj.rts ; P];
      obj.rts = sortRoots(obj.rts);
      obj.rts = obj.rts(:);
      obj.cleanRts();
      obj.N = length(obj.rts);
    end
    
    function obj = deleteRoot(obj, P)
      tol = 1e-6;
      obj.rts(find(abs(obj.rts - P) < tol)) = [];
    end
    
    function rts = cleanRts(obj)
      tol = 1e-5;
      indic = find(abs(obj.rts) > 1e4); % its assuming everything is freq. scaled
      for i = indic.'
        obj.K = obj.K*obj.rts(i);
        obj.rts(i) = [];
      end
      obj.rts = cleanRoots(obj.rts, tol);
      obj.rts = obj.rts(:);
      rts = obj.rts;
    end
    
    function conjPly = ctranspose(obj)
      conjPly = polyClass([],1);
      conjPly.rts = -obj.rts;
      if mod(obj.N, 2) == 1, conjPly.K = -obj.K; end
      conjPly.rts = conj(conjPly.rts);
    end

    function Eadd = plus(obj1,obj2)
      global imagRoots;
      funAdd = @(s) (obj1.peval(s) + obj2.peval(s));
      Eadd = polyClass([],1);

      N = max([obj1.N obj2.N]);
      Init = [-1j 0.5j 0.75j];
      tol = 1e-10;
      maxIter = 2500;

      val= muller(funAdd,Eadd,N,Init,tol,maxIter, imagRoots);
      Eadd = setK(funAdd, Eadd);
      Eadd.cleanRts();
    end

    function Eminus = minus(obj1,obj2)
      global imagRoots;
      funMinus = @(s) (obj1.peval(s) - obj2.peval(s));
      Eminus = polyClass([],1);

      N = max([obj1.N obj2.N]);
      Init = [-1j 0.5j 0.75j];
      tol = 1e-12;
      maxIter = 2500;

      val= muller(funMinus,Eminus,N,Init,tol,maxIter, imagRoots);
      Eminus = setK(funMinus, Eminus);
      Eminus.cleanRts();
    end

    function disp(obj)
      c = char(obj);
      if iscell(c)
        disp(['     ' c{:}])
      else
        disp(c)
      end
    end

    function val = peval(obj, w)
      if isempty(obj.rts)
        val = obj.K;
      elseif length(w) == 1
        val = 1;
        for a = (obj.rts).'
          val = val * (w - a);
        end
        val = val*obj.K;
      else
        n = length(w);
        Rts = obj.rts;
        B = repmat(Rts, 1, n);
        C = repmat(w(:).', obj.N, 1);
        val = prod(C - B);
        val = val.*obj.K;
        val = val(:);
      end
    end
  end
end

function str = char(obj)
   %newline = char([10]);
   %newline = char([]);

  if isempty(obj.rts)
    s = {[num2str(obj.K) '[]']};
    str = s;
    return
  else
    s = cell(1,1);
    ind = 1;
    %s(ind) = {[num2str(obj.K) '*' newline]};
    s(ind) = {[num2str(obj.K) '*']};
    ind = ind + 1;
    for a = (obj.rts).';
      if a ~= 0;
        %s(ind) = {['(s - ' num2str(a) ')' newline]};
        s(ind) = {['(s - ' num2str(a) ')']};
        ind = ind + 1;
      else
        %s(ind) = {['s' newline]};
        s(ind) = {['s']};
        ind = ind + 1;
      end
    end
  end
  str = [s{:}];
end