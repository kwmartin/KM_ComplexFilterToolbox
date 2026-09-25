function [ax1, ax2, r] = plotMgTwo(H, wp, ws, opts)
%   [ax1, ax2, r] = plotMgTwo(H, wp, ws, opts) plots the magnitude response
%   of one to three digital filters, with the passband zoom and the full
%   band in a single axes box (via plotTwo):
%     passband zoom (blue): x-axis at the BOTTOM, y-axis at the LEFT
%     full band     (red):  x-axis at the TOP,    y-axis at the RIGHT
%   Colour says which view a curve belongs to; line style (solid, dashed,
%   dotted) says which filter.
%
%   H    a zpk, or a cell of up to 3 zpk (e.g. {Hbase, Hfinal})
%   wp   passband edges in cycles, [f1 f2]
%   ws   stopband edges in cycles, e.g. [-0.499 ws1 ws2 0.499] as used by
%        the design functions; the inner edges are marked on the full-band
%        view. May be [].
%   opts (all optional):
%     .names       legend names, one per filter (default: no legend for a
%                  single filter, 'filter 1', 'filter 2', ... otherwise)
%     .title       figure title
%     .normalize   scale each filter to 0 dB at its passband peak
%                  (default true)
%     .zoomMargin  zoom x-range is wp +- zoomMargin*width (default 0.1)
%     .Ap          passband ripple (dB); if given, the zoom's y-range is
%                  limited to about 3*Ap below the peak
%     .zoomYlim    override the zoom's y-limits
%     .ymin        bottom of the full-band view (default: 40 dB below the
%                  highest stopband level, floored at -200)
%     .zoomColor .fullColor   default 'b' and 'r'
%     .legendLoc   legend location (default 'southoutside', horizontal)
%     .newFig      open a new figure (default true)
%     .file        if given, also export file.pdf and file.png with
%                  savePaperFig (.widthIn, .heightIn, .fontSize passed on)
%   r returns the plotted data: r.f, r.dB (full band), r.fz, r.dBz (zoom),
%   one column per filter.
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
    error('plotMgTwo plots at most 3 filters');
  end
  opts = setOpt(opts, 'normalize', true);
  opts = setOpt(opts, 'zoomMargin', 0.1);
  opts = setOpt(opts, 'legendLoc', 'southoutside');
  opts = setOpt(opts, 'zoomColor', 'b');
  opts = setOpt(opts, 'fullColor', 'r');
  opts = setOpt(opts, 'newFig', true);
  opts = setOpt(opts, 'title', '');
  opts = setOpt(opts, 'names', {});
  if isempty(opts.names) && nF > 1
    opts.names = arrayfun(@(k) sprintf('filter %d', k), 1:nF, 'UniformOutput', false);
  end
  toDb = 20/log(10);

  f = (-0.5:1e-4:0.5).';
  width = wp(2) - wp(1);
  xz = wp + [-1 1]*opts.zoomMargin*width;
  fz = linspace(xz(1), xz(2), 2001).';
  inWp = fz >= wp(1) & fz <= wp(2);
  dB = zeros(numel(f), nF);
  dBz = zeros(numel(fz), nF);
  for i = 1:nF
    dB(:, i) = toDb*real(col(AnlzDH(H{i}, 2*pi*f)));
    dBz(:, i) = toDb*real(col(AnlzDH(H{i}, 2*pi*fz)));
    if opts.normalize
      pk = max(dBz(inWp, i));
      dB(:, i) = dB(:, i) - pk;
      dBz(:, i) = dBz(:, i) - pk;
    end
  end

  % ---- zoom (bottom/left) ----
  if isfield(opts, 'zoomYlim') && ~isempty(opts.zoomYlim)
    zy = opts.zoomYlim;
  else
    zTop = max(dBz(:));
    zBot = min(dBz(:));
    if isfield(opts, 'Ap') && ~isempty(opts.Ap)
      zBot = max(zBot, zTop - 3*opts.Ap);
    end
    pad = 0.05*max(zTop - zBot, 0.01);
    zy = [zBot - pad, zTop + pad];
  end
  zoom.x = fz;  zoom.y = dBz;
  zoom.color = opts.zoomColor;
  zoom.xAxis = 'bottom';  zoom.yAxis = 'left';
  zoom.xlim = xz;  zoom.ylim = zy;
  zoom.xlabel = 'Passband frequency (cycles)';
  zoom.ylabel = 'Passband gain (dB)';
  zoom.xlines = wp;

  % ---- full band (top/right) ----
  [ws1, ws2] = innerEdges(ws, wp);
  if isfield(opts, 'ymin') && ~isempty(opts.ymin)
    ymin = opts.ymin;
  elseif ~isempty(ws1)
    inStop = f <= ws1 | f >= ws2;
    ymin = max(-200, max(max(dB(inStop, :))) - 40);
  else
    ymin = -100;
  end
  full.x = f;  full.y = dB;
  full.color = opts.fullColor;
  full.xAxis = 'top';  full.yAxis = 'right';
  full.xlim = [-0.5 0.5];  full.ylim = [ymin, max(dB(:)) + 5];
  full.xlabel = 'Frequency (cycles)';
  full.ylabel = 'Gain (dB)';
  full.xlines = [ws1 ws2];

  if opts.newFig
    fig = figure('Position', [800 100 800 800]);
  else
    fig = gcf;
  end
  [ax1, ax2] = plotTwo(zoom, full, opts.title, ...
      struct('fig', fig, 'grid', 1, 'legendNames', {opts.names}, ...
      'legendLoc', opts.legendLoc));

  if isfield(opts, 'file') && ~isempty(opts.file)
    savePaperFig(fig, opts.file, getOpt(opts, 'widthIn'), ...
        getOpt(opts, 'heightIn'), getOpt(opts, 'fontSize'));
  end
  r.f = f;  r.dB = dB;  r.fz = fz;  r.dBz = dBz;
end

function v = col(v)
  v = v(:);
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
