function [ax1, ax2, r] = plotGdTwo(H, wp, ws, opts)
%   [ax1, ax2, r] = plotGdTwo(H, wp, ws, opts) plots the group delay of one
%   to three digital filters, with the passband zoom and the full band in
%   a single axes box (via plotTwo):
%     passband zoom (blue): x-axis at the BOTTOM, y-axis at the LEFT
%     full band     (red):  x-axis at the TOP,    y-axis at the RIGHT
%   Colour says which view a curve belongs to; line style (solid, dashed,
%   dotted) says which filter. Group delay is in samples, from AnlzDH.
%
%   H    a zpk, or a cell of up to 3 zpk (e.g. {Hunequalized, Hequalized})
%   wp   passband edges in cycles/sample, [f1 f2] (labelled Hz: the
%        sample rate is taken as 1 Hz)
%   ws   stopband edges in cycles (inner edges marked on the full-band
%        view), or []
%   opts (all optional):
%     .names       legend names, one per filter (default: no legend for a
%                  single filter, 'filter 1', 'filter 2', ... otherwise)
%     .legend      set false to suppress the legend even with nF > 1 and
%                  no .names given (default true)
%     .title       figure title
%     .zoomMargin  zoom x-range is wp +- zoomMargin*width (default 0.1)
%     .zoomRelPct  plot the zoom as each filter's deviation from its own
%                  mean over wp, in % of that mean (default false). Use it
%                  to compare the ripple of filters whose delays differ.
%     .zoomYlim    override the zoom's y-limits (default: from the minimum
%                  over wp up to the maximum over the whole zoom window, so
%                  peaks just outside wp are not clipped, padded by 25% of
%                  the wp spread; not below 0 for absolute group delay that
%                  is non-negative over wp)
%     .gdMaxFctr   full-band y-range is [min(0, min over wp),
%                  gdMaxFctr*max over wp] (default 3). The limits clip
%                  the spikes near stopband zeros; the data are not edited.
%     .fullYlim    override the full-band y-limits
%     .alignMax    put the maximum group delay in the zoom window at the
%                  same height on both y-axes (default true; not with
%                  zoomRelPct)
%     .maskDb      if given, hide the group delay (NaN) wherever the gain is
%                  more than maskDb dB below the passband peak, where it
%                  has no practical meaning
%     .gdRef       group-delay value(s) drawn as dotted lines on the zoom
%                  (ignored with zoomRelPct)
%     .legendLoc   legend location (default 'southoutside', horizontal)
%     .zoomColor .fullColor   default 'b' and 'r'; each may be a cell of
%                  colours, one per filter, instead of a single colour --
%                  see plotTwo.m's .color
%     .markEdges   draw dotted lines at the wp edges (zoom) and the inner
%                  ws edges (full band) (default true)
%     .newFig      open a new figure (default true)
%     .pos         axes Position, passed to plotTwo (default: plotTwo's
%                  own default, a box filling most of the figure); pass a
%                  narrower rectangle to place this figure's box side by
%                  side with another plot in the same figure
%     .fig         figure to draw in when .newFig is false (default gcf)
%     .file        if given, also export file.pdf and file.png with
%                  savePaperFig (.widthIn, .heightIn, .fontSize, .refit
%                  passed on)
%   r returns the plotted data: r.f, r.gd (full band), r.fz, r.gdz (zoom),
%   one column per filter, r.gdZoom (what the zoom shows), plus r.p2pPct, the p2p group delay over wp as a
%   percentage of its mean, per filter.
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

  if nargin < 3, ws = []; end
  if nargin < 4, opts = struct(); end
  if ~iscell(H), H = {H}; end
  nF = numel(H);
  if nF > 3
    error('plotGdTwo plots at most 3 filters');
  end
  opts = setOpt(opts, 'zoomMargin', 0.1);
  opts = setOpt(opts, 'markEdges', true);
  opts = setOpt(opts, 'alignMax', true);
  opts = setOpt(opts, 'zoomRelPct', false);
  opts = setOpt(opts, 'legendLoc', 'southoutside');
  opts = setOpt(opts, 'gdMaxFctr', 3);
  opts = setOpt(opts, 'zoomColor', 'b');
  opts = setOpt(opts, 'fullColor', 'r');
  opts = setOpt(opts, 'newFig', true);
  opts = setOpt(opts, 'title', '');
  opts = setOpt(opts, 'names', {});
  opts = setOpt(opts, 'legend', true);
  if isempty(opts.names) && nF > 1 && opts.legend
    opts.names = arrayfun(@(k) sprintf('filter %d', k), 1:nF, 'UniformOutput', false);
  end
  toDb = 20/log(10);

  f = (-0.5:1e-4:0.5).';
  width = wp(2) - wp(1);
  xz = wp + [-1 1]*opts.zoomMargin*width;
  xz = [max(xz(1), -0.5), min(xz(2), 0.5)];   % stay within one period
  % include the exact wp edges, where the response is often steepest
  fz = unique([linspace(xz(1), xz(2), 2001).'; wp(:)]);
  inWp = fz >= wp(1) & fz <= wp(2);
  gd = zeros(numel(f), nF);
  gdz = zeros(numel(fz), nF);
  p2pPct = zeros(1, nF);
  for i = 1:nF
    [lg, ~, g] = AnlzDH(H{i}, 2*pi*f);
    [lgz, ~, gz] = AnlzDH(H{i}, 2*pi*fz);
    gd(:, i) = g(:);
    gdz(:, i) = gz(:);
    if isfield(opts, 'maskDb') && ~isempty(opts.maskDb)
      pk = max(lgz(inWp));
      gd(toDb*(lg(:) - pk) < -opts.maskDb, i) = NaN;
      gdz(toDb*(lgz(:) - pk) < -opts.maskDb, i) = NaN;
    end
    gw = gdz(inWp, i);
    p2pPct(i) = 100*(max(gw) - min(gw))/mean(gw);
  end
  gdWp = gdz(inWp, :);
  gdZoom = gdz;
  if opts.zoomRelPct
    mu = mean(gdWp, 1, 'omitnan');
    gdZoom = 100*(gdz - mu)./mu;
  end
  zWp = gdZoom(inWp, :);

  % ---- zoom (bottom/left) ----
  if isfield(opts, 'zoomYlim') && ~isempty(opts.zoomYlim)
    zy = opts.zoomYlim;
  else
    lo = min(zWp(:));  hi = max(zWp(:));
    pad = 0.25*max(hi - lo, 1e-3*max(abs([lo hi])));
    zy = [lo - pad, max(max(gdZoom(:)), hi) + pad];
    if ~opts.zoomRelPct && lo >= 0
      zy(1) = max(zy(1), 0);
    end
  end
  zoom.x = fz;  zoom.y = gdZoom;
  zoom.color = opts.zoomColor;
  if isfield(opts, 'lineStyle') && ~isempty(opts.lineStyle), zoom.lineStyle = opts.lineStyle; end
  zoom.xAxis = 'bottom';  zoom.yAxis = 'left';
  zoom.xlim = xz;  zoom.ylim = zy;
  zoom.xlabel = 'Passband frequency (Hz)';
  zoom.ylabel = 'Passband GD (samples)';
  zoom.xlines = wp;
  if ~opts.markEdges, zoom.xlines = []; end
  if opts.zoomRelPct
    zoom.ylabel = 'Passband GD deviation (%)';
  elseif isfield(opts, 'gdRef')
    zoom.ylines = opts.gdRef;
  end

  % ---- full band (top/right) ----
  [ws1, ws2] = innerEdges(ws, wp);
  if isfield(opts, 'fullYlim') && ~isempty(opts.fullYlim)
    fy = opts.fullYlim;
  else
    fy = [min(0, min(gdWp(:))), opts.gdMaxFctr*max(gdWp(:))];
    if opts.alignMax && ~opts.zoomRelPct
      % the zoom maximum h sits a fraction rTop = (zy(2) - h)/diff(zy)
      % down from the top of the zoom; choose the full band's top so it
      % sits the same fraction down there: (fTop - h) = rTop*(fTop - fy(1))
      h = max(max(gdz(:)), max(gdWp(:)));
      rTop = (zy(2) - h)/diff(zy);
      fy(2) = (h - rTop*fy(1))/(1 - rTop);
    end
  end
  full.x = f;  full.y = gd;
  full.color = opts.fullColor;
  if isfield(opts, 'lineStyle') && ~isempty(opts.lineStyle), full.lineStyle = opts.lineStyle; end
  full.xAxis = 'top';  full.yAxis = 'right';
  full.xlim = [-0.5 0.5];  full.ylim = fy;
  full.xlabel = 'Frequency (Hz)';
  full.ylabel = 'GD (samples)';
  full.xlines = [ws1 ws2];
  if ~opts.markEdges, full.xlines = []; end

  if opts.newFig
    fig = figure('Position', [800 100 800 800]);
  elseif isfield(opts, 'fig') && ~isempty(opts.fig)
    fig = opts.fig;
  else
    fig = gcf;
  end
  [ax1, ax2] = plotTwo(zoom, full, opts.title, ...
      struct('fig', fig, 'grid', 1, 'legendNames', {opts.names}, ...
      'legendLoc', opts.legendLoc, 'pos', getOpt(opts, 'pos'), ...
      'linkTag', getOpt(opts, 'linkTag')));

  if isfield(opts, 'file') && ~isempty(opts.file)
    savePaperFig(fig, opts.file, getOpt(opts, 'widthIn'), ...
        getOpt(opts, 'heightIn'), getOpt(opts, 'fontSize'), getOpt(opts, 'refit'));
  end
  r.f = f;  r.gd = gd;  r.fz = fz;  r.gdz = gdz;  r.p2pPct = p2pPct;
  r.gdZoom = gdZoom;
end

function [ws1, ws2] = innerEdges(ws, wp)
%   the stopband edges nearest the passband, or [] if ws is empty
  ws1 = [];  ws2 = [];
  if isempty(ws), return, end
  lo = ws(ws < wp(1));
  hi = ws(ws > wp(2));
  if ~isempty(lo) && ~isempty(hi)
    ws1 = max(lo);  ws2 = min(hi);
  end
end

function opts = setOpt(opts, name, val)
  if ~isfield(opts, name) || (isempty(opts.(name)) && ~iscell(opts.(name)))
    opts.(name) = val;
  end
end

function v = getOpt(opts, name)
  v = [];
  if isfield(opts, name), v = opts.(name); end
end
