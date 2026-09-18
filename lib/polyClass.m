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
          if isempty(rts(imag(rts) ~= 0))
              rts = sort(rts);
          else
              rts = sortRoots(rts);
          end
          obj.rts = rts;
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
      % Iterate in descending order: deleting obj.rts(i) shifts every later
      % (higher) index down by one, so processing ascending indices (as
      % originally written) makes later entries in indic stale once an
      % earlier one is removed, eventually indexing past the shrunk array.
      for i = sort(indic, 'descend').'
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

      if obj1.K == 0
        Eadd = obj2;
        return
      end

      if obj2.K == 0
        Eadd = obj1;
        return
      end

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

      if obj1.K == 0
        Eminus = obj2;
        Eminus.K = - Eminus.K;
        return
      end

      if obj2.K == 0
        Eminus = obj1;
        return
      end
      
      N = max([obj1.N obj2.N]);
      Init = [-1j 0.5j 0.75j];
      tol = 1e-12;
      maxIter = 2500;

      val= muller(funMinus,Eminus,N,Init,tol,maxIter, imagRoots);
      Eminus = setK(funMinus, Eminus);
      Eminus.cleanRts();
    end

    function Emlt = mtimes(obj1,obj2)
      if isa(obj1,'polyClass') && isa(obj2,'double')
          Emlt = polyClass(obj1.rts,obj1.K);
          Emlt.K = obj1.K * obj2;
      elseif isa(obj1,'double') && isa(obj2,'polyClass')
          Emlt = polyClass(obj2.rts,obj2.K);
          Emlt.K = obj2.K * obj1;
      elseif isa(obj1,'polyClass') && isa(obj2,'polyClass')
          Emlt = polyClass([],1);
          Emlt.rts = [obj1.rts; obj2.rts];
          Emlt.K = obj1.K*obj2.K;
          Emlt.N = obj1.N + obj2.N;
      else
            error('Multiplication is only supported for doubles or polyClass objects');
      end

    end

    function disp(obj)
      c = char(obj);
      if iscell(c)
        disp(['     ' c{:}])
      else
        disp(c)
      end
    end

    function Eevn = getEvn(obj)
      % Eevn = getEvn(obj) returns the even part of obj. Uses roots()
      % directly on the exact even-part coefficient vector (see
      % evnOddImpl) -- far more accurate and 10-17x faster than the
      % Muller-based getEvnMuller across a broad validation sweep (see
      % examples/tst_getEvnOdd.m); prefer this unless you specifically
      % need to reproduce getEvnOddPly.m's/getEvnMuller's exact behavior.
      [Eevn, ~] = evnOddImpl(obj);
    end

    function Eodd = getOdd(obj)
      % Eodd = getOdd(obj) returns the odd part of obj. See getEvn.
      [~, Eodd] = evnOddImpl(obj);
    end

    function Eevn = getEvnMuller(obj)
      % Eevn = getEvnMuller(obj) returns the even part of obj using the
      % original Muller-root-finding approach (a direct port of
      % getEvnOddPly.m as a polyClass method). Kept for comparison/
      % reference; getEvn is recommended for new code (see its docstring
      % and examples/tst_getEvnOdd.m).
      [Eevn, ~] = evnOddMullerImpl(obj);
    end

    function Eodd = getOddMuller(obj)
      % Eodd = getOddMuller(obj) returns the odd part of obj using the
      % original Muller-root-finding approach. See getEvnMuller.
      [~, Eodd] = evnOddMullerImpl(obj);
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

function [Eevn, Eodd] = evnOddMullerImpl(obj)
% Shared implementation behind the getEvnMuller/getOddMuller methods. This
% is a direct port of getEvnOddPly.m's algorithm (see that file/
% lib/Fix_Lddr_Rlznts.md for the underlying math and history) operating on
% obj instead of a passed-in argument, kept in lock-step with it for
% comparison purposes. See evnOddImpl for the recommended (roots()-based)
% implementation behind the default getEvn/getOdd methods.

rts = obj.rts;
if isempty(find(abs(real(rts)) > 1e-5))
    if mod(obj.N, 2) == 0
        Eevn = polyClass(obj);
        Eodd = polyClass();
    else
        Eevn = polyClass();
        Eodd = polyClass(obj);
    end
    return
end
Etf = poly(rts);
Netf = length(Etf);
if mod(Netf, 2) == 1
    sgns = (-1).^(0:(Netf-1));
else
    sgns = (-1).^(1:(Netf));
end
Etfevn = (Etf + conj(Etf).*sgns)/2;
Etfevn = reduceLeadTF(Etfevn);
Etfodd = (Etf - conj(Etf).*sgns)/2;
Etfodd = reduceLeadTF(Etfodd);
Nevn = length(Etfevn) - 1;
Nodd = length(Etfodd) - 1;

% Now that we know the order we find the roots
% of the even and odd polynomials using more
% accurate zero finding based on Muller

obj2 = obj'; % obj2 = conj(obj(-s))
funEvn = @(s) (obj.peval(s) + obj2.peval(s))/2.0;
funOdd = @(s) (obj.peval(s) - obj2.peval(s))/2.0;
Eevn = polyClass();
Eevn.K = 1;
Eodd = polyClass();
Eodd.K = 1;

Init = [-2j j 3j];
tol = 1e-14;
maxIter = 1000;

if Nevn <= 1
    Evn.rts = [];
    Evn.K = 0;
else
    val= muller(funEvn,Eevn,Nevn,Init,tol,maxIter);
    Eevn.cleanRts();
    Eevn = setK(funEvn, Eevn);
end

if Nodd < 1
    Eodd.rts = [];
    Eodd.K = 0;
else
    val= muller(funOdd,Eodd,Nodd,Init,tol,maxIter);
    Eodd = setK(funOdd, Eodd);
    Eodd.cleanRts();
end
end

function [Eevn, Eodd] = evnOddImpl(obj)
% Shared implementation behind the default getEvn/getOdd methods. Avoids
% Muller point iteration (and its Newton polishing, which is
% ill-conditioned at repeated roots) and setK's forced-real-gain
% assumption (wrong for genuinely complex-coefficient polynomials)
% entirely -- see evnOddMullerImpl for that (legacy, getEvnMuller/
% getOddMuller) approach.
%
% Etf=poly(rts) and the even/odd coefficient split (Etfevn/Etfodd) are
% *exact* -- evnOddMullerImpl already computes them, but only uses them to
% count the degree before re-deriving the same roots less directly via
% Muller. Since Etfevn/Etfodd ARE the exact coefficient vectors of the
% even/odd parts (up to the overall obj.K scale, which doesn't affect
% root locations), MATLAB's built-in roots() -- a mature, robust
% eigenvalue-based solver -- finds them directly with no iteration to
% fail to converge. The gain is then just obj.K times the leading
% (post-reduction) coefficient; no setK/cleanRts needed.
%
% Unlike evnOddMullerImpl, this does not zero out low-degree (Nevn<=1 /
% Nodd<1) components -- that shortcut in the original algorithm silently
% discards a genuinely nonzero linear/constant part.

rts = obj.rts;
if isempty(find(abs(real(rts)) > 1e-5))
    if mod(obj.N, 2) == 0
        Eevn = polyClass(obj);
        Eodd = polyClass();
    else
        Eevn = polyClass();
        Eodd = polyClass(obj);
    end
    return
end

Etf = poly(rts);
Netf = length(Etf);
if mod(Netf, 2) == 1
    sgns = (-1).^(0:(Netf-1));
else
    sgns = (-1).^(1:(Netf));
end
Etfevn = reduceLeadTF((Etf + conj(Etf).*sgns)/2);
Etfodd = reduceLeadTF((Etf - conj(Etf).*sgns)/2);

if isempty(Etfevn)
    Eevn = polyClass();
    Eevn.K = 0;
else
    Eevn = polyClass(roots(Etfevn), obj.K*Etfevn(1));
end

if isempty(Etfodd)
    Eodd = polyClass();
    Eodd.K = 0;
else
    Eodd = polyClass(roots(Etfodd), obj.K*Etfodd(1));
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
        s(ind) = {['(s - (' num2str(a) '))']};
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