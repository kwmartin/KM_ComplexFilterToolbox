function [H T0] = LinPhFltr(n, deltT, ap)
%   [H T0] = LinPhFltr(n, deltT) returns an all-pole filter or order n having equi-ripple
%   group delay. T0 is the average passband delay
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
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
  warning('off', 'Control:ltiobject:ZPKComplex');

  options = optimoptions('fsolve','Display','none');
  options.TolFun = 1e-16;
  options.TolX = 1e-8;
  options.MaxFunEvals = 5000;
  options.MaxIter = 1000;

  srt = @(p) conj(sort(p, 'ComparisonMethod', 'real'));
  h1 = bessel_filt(n, [-1 1], 3.0103);
  [z1 p1 k] = zpkdata(h1,'vector');
  Fctr = (n + 1.2)/3.2;
  p1 = p1./Fctr;
  s2z = @(s)-sqrt(1 + 1./(s.^2));
  z2s = @(z)-1./sqrt(z.^2 - 1);
  Z1 = s2z(p1).';

  % besselRts's system only corresponds to a valid real filter when p stays
  % exactly conjugate-symmetric - but fsolve treats each of the n complex
  % root unknowns as fully independent. For some deltT values it converges
  % to a solution that satisfies the n+1 residual equations componentwise
  % while drifting away from conjugate symmetry entirely (confirmed: for
  % deltT roughly in [0.86, 1.3] at n=7, the "solution" pairs up as
  % near-duplicates with matching-sign imaginary parts instead of true
  % conjugate pairs, so cplxpair below correctly refuses to pair them - no
  % tolerance loosening fixes that, since they genuinely aren't conjugates).
  %
  % Fix, same principle as place_poles_sym.m for a different solver: only
  % solve for the independent ("master") half of the roots - one per
  % conjugate pair, plus any purely real root - and reconstruct each mirror
  % root as the exact conjugate on every evaluation, so exact conjugate
  % symmetry is structural rather than something fsolve has to discover.
  %
  % Solving the reduced (symmetric) system directly from the generic [Z1 n]
  % guess turned out to be numerically harder for fsolve's trust-region
  % algorithm than the unconstrained problem (it stalls, exitflag<=0), even
  % though the reduced formulation is verified correct (its residual is ~0
  % and stays there when evaluated/started at a known-good symmetric
  % solution). So: run the unconstrained solve first to get into the right
  % neighbourhood (it reliably finds *a* nearby root), project that onto
  % the symmetric subspace (average each master with its mirror's
  % conjugate) as the seed, then run a short reduced-system refinement to
  % clean up the remaining asymmetry exactly. If the unconstrained solve
  % itself lands on a genuinely different (non-symmetric) root - confirmed
  % this happens for a narrow deltT band even with many random-restarted
  % initial guesses, not just bad luck with one guess - the refinement
  % can't rescue it either, so fail with a clear diagnostic instead of the
  % opaque cplxpair crash this used to hit.
  isRealZ1 = abs(imag(Z1)) < 1e-9*max(abs(Z1));
  masterIdx = find(isRealZ1 | imag(Z1) > 0);
  mirrorIdx = find(~isRealZ1 & imag(Z1) < 0);
  isRealMaster = isRealZ1(masterIdx);
  mirrorOf = zeros(size(masterIdx));
  nonRealMaster = find(~isRealMaster);
  for mi = nonRealMaster
      [~, mj] = min(abs(Z1(mirrorIdx) - conj(Z1(masterIdx(mi)))));
      mirrorOf(mi) = mirrorIdx(mj);
  end

  fndRts = @(x)besselRts(x, deltT);
  rtsUnc = fsolve(fndRts, [Z1 n], options);

  seedMaster = rtsUnc(masterIdx);
  seedMaster(nonRealMaster) = 0.5*(rtsUnc(masterIdx(nonRealMaster)) + conj(rtsUnc(mirrorOf(nonRealMaster))));
  fndRtsSym = @(xMaster) selectMasterResiduals( ...
      besselRts([expandSymRoots(xMaster(1:end-1), n, masterIdx, mirrorOf, isRealMaster), xMaster(end)], deltT), ...
      masterIdx);
  [xMasterSolved, symFval] = fsolve(fndRtsSym, [seedMaster, rtsUnc(end)], options);
  pFull = expandSymRoots(xMasterSolved(1:end-1), n, masterIdx, mirrorOf, isRealMaster);
  rts = [pFull, xMasterSolved(end)];

  % expandSymRoots makes symmetry exact by construction regardless of
  % whether fsolve actually converged, so checking symmetry error here
  % would be vacuous - check the residual (how well the equations are
  % actually satisfied) instead.
  % There's a wide margin between genuine convergence (residual <=~1e-5,
  % including cases where fsolve's trust region collapses just short of a
  % clean exitflag=1/2/3 despite already being at a good answer) and a
  % genuinely bad root (residual O(1) or worse, confirmed by many
  % random-restarted initial guesses landing in the same regime) - 1e-3
  % sits well inside that gap.
  resErr = max(abs(symFval));
  if resErr > 1e-3
      % The direct solve (above) landed on a genuinely bad root for this
      % deltT - confirmed this happens for a narrow band (e.g. deltT in
      % roughly [0.86, 0.9] at n=7) even across many random-restarted
      % initial guesses, so retrying from another generic guess won't help.
      % What does help: continuation. deltT=0.25 is a reliable anchor (the
      % direct solve above is essentially always good there), and stepping
      % from it to the target in small increments, reseeding the reduced
      % (symmetric) solve from each previous step's result, tracks the
      % solution through the hard region instead of asking fsolve to find
      % it cold. Verified this converges (residual ~1e-8) for every
      % problem deltT found so far. Only invoked as a fallback, not the
      % default path, because it's ~10-40x more fsolve calls and isn't
      % needed (or, checked separately, doesn't even work as well without
      % a nearby anchor) for the common case.
      deltTAnchor = 0.25;
      if abs(deltT - deltTAnchor) < 1e-12
          resErrCont = resErr; % already at the anchor; nothing to continue from
      else
          fndRtsAnchor = @(x)besselRts(x, deltTAnchor);
          rtsAnchor = fsolve(fndRtsAnchor, [Z1 n], options);
          seedAnchor = rtsAnchor(masterIdx);
          seedAnchor(nonRealMaster) = 0.5*(rtsAnchor(masterIdx(nonRealMaster)) + conj(rtsAnchor(mirrorOf(nonRealMaster))));
          fndRtsSymAnchor = @(xMaster) selectMasterResiduals( ...
              besselRts([expandSymRoots(xMaster(1:end-1), n, masterIdx, mirrorOf, isRealMaster), xMaster(end)], deltTAnchor), ...
              masterIdx);
          xCont = fsolve(fndRtsSymAnchor, [seedAnchor, rtsAnchor(end)], options);

          nSteps = max(10, ceil(abs(deltT - deltTAnchor)/0.03));
          deltTPath = linspace(deltTAnchor, deltT, nSteps);
          contFval = [];
          for dTStep = deltTPath(2:end)
              fndRtsSymStep = @(xMaster) selectMasterResiduals( ...
                  besselRts([expandSymRoots(xMaster(1:end-1), n, masterIdx, mirrorOf, isRealMaster), xMaster(end)], dTStep), ...
                  masterIdx);
              [xCont, contFval] = fsolve(fndRtsSymStep, xCont, options);
          end
          xMasterSolved = xCont;
          pFull = expandSymRoots(xMasterSolved(1:end-1), n, masterIdx, mirrorOf, isRealMaster);
          rts = [pFull, xMasterSolved(end)];
          resErrCont = max(abs(contFval));
      end
      if resErrCont > 1e-3
          error('LinPhFltr:unconvergedSolution', ...
              ['LinPhFltr(n=%d, deltT=%.6g, ap=%.6g): fsolve could not find a ' ...
              'conjugate-symmetric equi-ripple solution, even via ' ...
              'continuation from deltT=%.4g (best residual %.4g direct, ' ...
              '%.4g via continuation) - no valid real filter found for ' ...
              'this spec'], n, deltT, ap, deltTAnchor, resErr, resErrCont);
      end
  end

  p2 = z2s(rts(1:end-1)).';
  p2 = cplxpair(p2, 1e-7);
  p2 = sortReal(p2);
  T0 = rts(end);
  h2 = zpk(z1, p2, k);
  [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, 0);
  h2.k = h2.k/exp(lgH);

  w = 1;
  ep = -ap*log(10)/20; % desired loss in nepers
  for i = 1:10
    [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, w);
    w = w - (lgH - ep)./dLdW;
  end
  H = scaleZPK(h2, 1.0/w);

% In 2026 I don't remember what the purpose of the following is. It does fsolve with deltT/w
% but it ends with the same lgH = -0.346573595272 at w=1
%  for j = 1:5
%     fndRts = @(x)besselRts(x, deltT/w);
%     [rts, fval, exitflag, output] = fsolve(fndRts,rts,options);
%     p2 = z2s(rts(1:end-1)).';
%     p2 = cplxpair(p2, 1e-7);
%     p2 = sortReal(p2);
%     T0 = rts(end);
%     h2 = zpk(z1, p2, k);
%     [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, 0);
%     h2.k = h2.k/exp(lgH);
%     w = 1;
%     ep = -ap*log(10)/20; % desired loss in nepers
%     for i = 1:10
%       [lgH, phH, gdH, dLdW, dTdW] = AnlzH(h2, w);
%       w = w - (lgH - ep)./dLdW;
%     end
%   end
  H = scaleZPK(h2, 1.0/w);

  plot_am_ph_gd(H, [-1.5 1.5], 'b');
  plot_crsps(H,[-1 1],[-1.5 1.5],'b',[-10 10 -120 1]);
  [deltT deriv] = fnd_gd_ripple(H,[0 1]);

  a = 1;
end

function pFull = expandSymRoots(xMaster, n, masterIdx, mirrorOf, isRealMaster)
%   Rebuild the full n-element root vector from the master (independent)
%   half, reconstructing each mirror root as the exact conjugate of its
%   master - see the fsolve call in LinPhFltr for why.
    pFull = zeros(1, n);
    pFull(masterIdx) = xMaster;
    nonReal = ~isRealMaster;
    pFull(mirrorOf(nonReal)) = conj(xMaster(nonReal));
end

function Rsel = selectMasterResiduals(Rts, masterIdx)
%   besselRts returns n+1 residuals (1 shared + n per-pole); with exact
%   conjugate symmetry enforced by expandSymRoots, each mirror pole's
%   residual is guaranteed to be the complex conjugate of its master's, so
%   solving only the master residuals (plus the shared one) is enough - see
%   the fsolve call in LinPhFltr.
    Rsel = [Rts(1), Rts(masterIdx+1)];
end
