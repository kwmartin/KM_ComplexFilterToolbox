function test_plot_helpers()
%   test_plot_helpers() checks plotTwo/plotGdTwo/plotMgTwo/combinedMagGdFig
%   against small synthetic filters (a handful of poles -- no design
%   iteration, so this runs in about a second) and asserts on the actual
%   drawn Line objects: how many there are, and whether every one is
%   visually distinguishable from every other (distinct colour, or same
%   colour but distinct line style). That is the property the last few
%   rounds of hand-inspecting paper-figure screenshots kept finding
%   broken -- two curves sharing both colour and style collapse into what
%   reads as one curve -- so it is now checked here instead of by
%   regenerating the 5-minute paper script and eyeballing a screenshot.
%
%   Run this after any change to lib/plotTwo.m, plotMgTwo.m, plotGdTwo.m
%   or combinedMagGdFig.m, before regenerating the real paper figures with
%   examples/paper_figs_scld.m. Errors (via error()) on the first failed
%   check with a description of what was wrong; prints ALL PASSED and
%   returns normally otherwise. Also writes
%   <tempdir>/test_plot_helpers/*.png so the curves can still be eyeballed
%   if a check fails and the reason isn't obvious from the message alone.
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2026  Kenneth Martin
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

  oldVis = get(0, 'DefaultFigureVisible');
  set(0, 'DefaultFigureVisible', 'off');
  restoreVis = onCleanup(@() set(0, 'DefaultFigureVisible', oldVis));

  outDir = fullfile(tempdir, 'test_plot_helpers');
  if ~exist(outDir, 'dir'), mkdir(outDir); end

  wp = [0.05 0.15];
  ws = [-0.45 -0.2 0.2 0.45];
  H1 = synthFltr(0.90, 0.10);   % "before": sharper, more delay ripple
  H2 = synthFltr(0.55, 0.10);   % "after":  flatter

  checkPlotGdTwoOneFilter(outDir, H1, wp, ws);
  checkPlotGdTwoTwoFilters(outDir, H1, H2, wp, ws);
  checkPlotMgTwoOneFilter(outDir, H1, wp, ws);
  checkCombinedMagGdFigFourTraces(outDir, H1, H2, wp, ws);

  fprintf('test_plot_helpers: ALL PASSED (figures in %s)\n', outDir);
end

function H = synthFltr(r, f0)
%   a quick synthetic complex bandpass zpk centred near f0 cycles/sample:
%   a handful of poles at radius r, no zeros -- enough for AnlzDH to see
%   real magnitude/group-delay structure, without a slow filter design
  theta = 2*pi*f0*(0.5:0.1:1.5);
  H = zpk([], r*exp(1j*theta(:)), 1, 1);
end

function checkPlotGdTwoOneFilter(outDir, H1, wp, ws)
%   one filter: exactly 2 lines (zoom, full), distinct from each other
  fig = figure('Visible', 'off');
  plotGdTwo(H1, wp, ws, struct('markEdges', false, 'legend', false, ...
      'newFig', false, 'fig', fig));
  assertDistinctLines(findall(fig, 'Type', 'line'), 2, 'plotGdTwo, 1 filter');
  exportgraphics(fig, fullfile(outDir, 'plotGdTwo_1filter.png'));
  close(fig);
end

function checkPlotGdTwoTwoFilters(outDir, H1, H2, wp, ws)
%   two filters, default colours: 4 lines (2 filters x zoom/full), still
%   all pairwise distinct with plotGdTwo's own defaults (no caller styling)
  fig = figure('Visible', 'off');
  opts = struct('markEdges', false, 'legend', false, 'newFig', false, 'fig', fig);
  opts.zoomColor = {'b', 'g'};
  opts.fullColor = {'r', 'm'};
  plotGdTwo({H1, H2}, wp, ws, opts);
  assertDistinctLines(findall(fig, 'Type', 'line'), 4, 'plotGdTwo, 2 filters');
  exportgraphics(fig, fullfile(outDir, 'plotGdTwo_2filters.png'));
  close(fig);
end

function checkPlotMgTwoOneFilter(outDir, H1, wp, ws)
  fig = figure('Visible', 'off');
  plotMgTwo(H1, wp, ws, struct('markEdges', false, 'newFig', false, 'fig', fig));
  assertDistinctLines(findall(fig, 'Type', 'line'), 2, 'plotMgTwo, 1 filter');
  exportgraphics(fig, fullfile(outDir, 'plotMgTwo_1filter.png'));
  close(fig);
end

function checkCombinedMagGdFigFourTraces(outDir, H1, H2, wp, ws)
%   the actual function the paper script calls, with its actual default
%   beforeStyle (thin grey, no override) -- the real regression test: it
%   must exercise the same call shape as examples/paper_figs_scld.m, or it
%   proves nothing about what the paper actually gets. (Fig 2 and Fig 3
%   drifted apart the first time exactly because one caller passed an
%   explicit style override and one didn't, and this test used to always
%   pass the override too, so it never would have caught that.)
%
%   The GD panel draws 4 lines (2 filters x zoom/full), all 4 pairwise
%   distinct by design: passband zoom is blue (after) / light green
%   (before), full band is red (after) / grey (before) -- colour alone
%   tells all four apart, on top of "after" being heavier than "before".
%
%   Distinctness is checked separately within each panel (mag, GD): the
%   two panels are side-by-side, non-overlaid boxes, so a mag-panel curve
%   and a GD-panel curve are free to share an appearance -- only curves
%   overlaid in the SAME box (zoom+full share one Position, per plotTwo)
%   need to look different from each other.
  file = fullfile(outDir, 'combinedMagGdFig_test');
  posL = [0.14 0.22 0.25 0.60];   % must match combinedMagGdFig.m's own
  posR = [0.65 0.22 0.25 0.60];
  [~, r] = combinedMagGdFig(H1, {H1, H2}, wp, ws, [], {}, file);
  fig = gcf;
  assertDistinctLines(linesInPanel(fig, posL), 2, 'combinedMagGdFig mag panel');
  assertDistinctLines(linesInPanel(fig, posR), 4, 'combinedMagGdFig GD panel');
  if numel(r.p2pPct) ~= 2
    error('test_plot_helpers:combinedMagGdFig: expected 2 filters'' worth of p2pPct, got %d', ...
        numel(r.p2pPct));
  end
  close(fig);
end

function lns = linesInPanel(fig, pos)
%   the line objects belonging to the (possibly several, overlaid)
%   axes whose Position matches pos -- i.e. one plotTwo panel
  ax = findall(fig, 'Type', 'axes');
  inPanel = false(numel(ax), 1);
  for i = 1:numel(ax)
    inPanel(i) = all(abs(get(ax(i), 'Position') - pos) < 1e-9);
  end
  lns = findall(ax(inPanel), 'Type', 'line');
end

function lns = visibleLines(lns)
%   drops line objects with no finite data, or with Color 'none' -- e.g.
%   combinedMagGdFig's invisible placeholder for a "before" curve it
%   instead draws as dot markers (see addDottedCurve in combinedMagGdFig.m)
  keep = false(numel(lns), 1);
  for i = 1:numel(lns)
    yd = get(lns(i), 'YData');
    keep(i) = any(isfinite(yd)) && ~isequal(get(lns(i), 'Color'), 'none');
  end
  lns = lns(keep);
end

function assertDistinctLines(lns, nExpected, label)
%   errors unless lns has exactly nExpected visible line objects, and
%   every pair differs in colour, line style or marker (the "reads as a
%   separate curve" property)
  lns = visibleLines(lns);
  n = numel(lns);
  if n ~= nExpected
    error('test_plot_helpers:%s: expected %d line(s), found %d', ...
        label, nExpected, n);
  end
  for i = 1:n
    for k = (i+1):n
      sameColor = isequal(get(lns(i), 'Color'), get(lns(k), 'Color'));
      sameStyle = isequal(get(lns(i), 'LineStyle'), get(lns(k), 'LineStyle'));
      sameMarker = isequal(get(lns(i), 'Marker'), get(lns(k), 'Marker'));
      if sameColor && sameStyle && sameMarker
        error(['test_plot_helpers:%s: line %d and %d share both colour ' ...
            '[%s] and style ''%s'' -- they will read as one curve'], ...
            label, i, k, mat2str(get(lns(i), 'Color'), 3), get(lns(i), 'LineStyle'));
      end
    end
  end
end
