classdef (ConstructOnLoad = true) filterClass
  % The ladderClass object only contains LC components, not terminating resistors
  properties
    H = tf(1,1);
    F = [];
    E = [];
    P = [];
    wps = [];

    ordr = [1,1];
    X1o = tf(1,1);
    X1s = tf(1,1);
    X2o = tf(1,1);
    X2s = tf(1,1);
    rmvlOrdr = [];
  end
  methods
    function obj = filterClass(H, F)
      % obj.ladderElems(1) = ladderElem;
      if nargin == 0
        obj.H= tf(1,1);
        obj.F= tf(1,1);
      else
        obj.H= H;
        obj.F= F;
        Fpl = poly(F);
        Fpl = (Fpl + conj(Fpl))/2.0;
        [Ppl, Epl] = tfdata(H, 'v');
        wps = Ppl;
        Ppl = (Ppl + conj(Ppl))/2.0;
        Epl = (Epl + conj(Epl))/2.0;
        %Ppl = poly(P);
        Ppl = (Ppl + conj(Ppl))/2.0;
        Eevn = getEven(Epl);
        Eodd = getOdd(Epl);
        Fevn = getEven(Fpl);
        Fodd = getOdd(Fpl);
        peven = mod(length(Ppl), 2);
        [X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXs(peven, Eevn, Eodd, Fevn, Fodd)
        rts = imag(roots(Ppl));
        obj.wps = sort(rts(rts > 0));
      end
      obj.ordr = fndOrdr(H);
    end
    function obj = addElem(obj, br)
      obj.size = obj.size + 1;
      obj.ladderElems(obj.size) = ladderElem(br.C, br.L, br.X, br.Y, br.type);
    end
  end
end
