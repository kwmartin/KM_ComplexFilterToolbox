% Shrinks the dig_linPh_0_2_0-style passband (width 0.1 cycles down to
% 1e-12 cycles) and compares two design chains (see ScldGD.md
% sections 7 and 10):
%   dsgnDigitalFltr_scld  - group-delay extrema found on a fixed w grid
%                           (fndZeroCrs3_scld, step 2*pi*1e-5)
%   dsgnDigitalFltrX_scld - extrema found on a grid uniform in the
%                           band-centred transformed variable (fndZeroCrsX_scld)
% Prints the passband group-delay ripple and loss of each final design.
% Takes about 4 minutes.

figVis = get(0, 'DefaultFigureVisible'); warnState = warning;
set(0,'DefaultFigureVisible','off'); warning('off','all');
for Ordr = [3 5 7]
for s = [1 1e-2 1e-3 1e-4 1e-5 1e-6 1e-7 1e-9 1e-11]
  wp = [-0.05 0.05]*s; ws = [-0.499 -0.1*s 0.1*s 0.499]; p = [-0.3 0.3];
  as = [20 20 20 20]; px = []; ni = 0; Ap = 3.0103;
  for fn = {'dsgnDigitalFltr_scld', 'dsgnDigitalFltrX_scld'}
    t0 = tic;
    try
      [out, H] = evalc([fn{1} '(p,px,ni,wp,ws,as,Ap,''equiGDLsPls'',Ordr)']);
      close all;
      f = linspace(wp(1), wp(2), 2001); [lg,~,gd] = AnlzDH(H, 2*pi*f);
      msg = regexp(out, '(skipping adaptP3\w*|reverting[^\n]*|adaptP3\w* failed[^\n]*)', 'match', 'once');
      fprintf('n=%d s=%-6g %-22s GD ripple %7.3f%%  passband %5.2f dB  %3.0fs %s\n', Ordr, s, fn{1}, ...
        100*(max(gd)-min(gd))/mean(gd), -20/log(10)*(min(lg)-max(lg)), toc(t0), msg);
    catch ME
      fprintf('n=%d s=%-6g %-22s ERROR %s\n', Ordr, s, fn{1}, ME.message);
    end
  end
end
end
set(0, 'DefaultFigureVisible', figVis); warning(warnState);
a = 1;
