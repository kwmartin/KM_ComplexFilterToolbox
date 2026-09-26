function [ax1, ax2, h1, h2] = plotTwo(c1, c2, figTitle, opts)
%   [ax1, ax2, h1, h2] = plotTwo(c1, c2, figTitle, opts) plots two sets of
%   curves on two overlaid axes that share one box.
%
%   Default layout (as used by plot_dam_ph1):
%     c1 (red):  x-axis at the TOP,    y-axis at the LEFT
%     c2 (blue): x-axis at the BOTTOM, y-axis at the RIGHT
%   Either can be changed with the .xAxis and .yAxis fields (plotMgTwo and
%   plotGdTwo put the passband zoom at bottom/left and the full band at
%   top/right).
%
%   How it works: two axes share the same Position. ax1 (c1) sits
%   underneath with a white background; ax2 (c2) sits on top with a
%   transparent background. Each axis and its tick labels take the colour
%   of its own curves. The curves are drawn with line(), not plot(),
%   because plot() resets axes properties such as XAxisLocation and
%   YAxisLocation. linkprop keeps the two axes lined up on resize.
%
%   Struct fields (only x and y are required):
%     .x .y            data; .y may be a matrix with one column per curve
%                      (e.g. one per filter), and .x a vector or a matrix
%                      of the same size
%     .color           default 'r' for c1, 'b' for c2. A single value
%                      colours the axis ticks/labels and every curve (as
%                      before). A cell array of values, one per column of
%                      .y, gives each curve its own colour instead, while
%                      the axis ticks/labels/marker-lines keep this set's
%                      default identity colour ('r' for c1, 'b' for c2) --
%                      the pair still reads as "which view", with colour
%                      now free to also say "which curve".
%     .lineStyle       cell of styles, one per column of .y;
%                      default {'-', '--', ':'}
%     .xAxis .yAxis    'top'/'bottom' and 'left'/'right'; defaults as above
%     .xlim .ylim      [min max]; default is the finite data range
%     .xlabel .ylabel  axis label strings
%     .name            legend entry for this set (char), as in plot_dam_ph1
%     .lineWidth       default 1.5
%     .xlines .ylines  positions of dotted vertical/horizontal marker lines
%                      drawn on this set's axes, in its colour
%
%   opts (all optional):
%     .fig          figure to draw in (default gcf)
%     .grid         which axes gets the grid: 1, 2 or 0 (default 1)
%     .legendNames  cellstr, one name per column of .y: the legend then
%                   shows the line styles in black, so it identifies the
%                   curves (e.g. filters) independently of which axes
%                   they are on. Overrides .name.
%     .legendLoc    default 'best'; 'northoutside'/'southoutside' give a
%                   horizontal legend
%     .linkX        link the two x-axes' limits (default false)
%     .pos          axes Position (default [0.13 0.11 0.72 0.72], leaving
%                   room for the top x-axis and title); pass a narrower
%                   rectangle to place this plotTwo box side by side with
%                   another one in the same figure (see plotGdTwo's/
%                   plotMgTwo's own .pos)
%     .linkTag      appdata key for this call's axis-position link
%                   object (default 'plotTwoLink'); pass a distinct tag
%                   for each plotTwo call sharing one figure, or the
%                   second call's link silently replaces the first's
%
%   Returns both axes handles and the line handles of each set.
%
%   Later adjustments, e.g.:  ylim(ax2, [-180 180]);  xlim(ax1, [0.1 0.2]);
%   Zoom and pan act only on the top axes (ax2).
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

if nargin < 3, figTitle = ''; end
if nargin < 4, opts = struct(); end
c1 = setDefaults(c1, 'r', 'top', 'left');
c2 = setDefaults(c2, 'b', 'bottom', 'right');
if ~isfield(opts, 'fig') || isempty(opts.fig), opts.fig = gcf; end
if ~isfield(opts, 'grid') || isempty(opts.grid), opts.grid = 1; end
if ~isfield(opts, 'legendNames'), opts.legendNames = {}; end
if ~isfield(opts, 'legendLoc') || isempty(opts.legendLoc), opts.legendLoc = 'best'; end
if ~isfield(opts, 'linkX') || isempty(opts.linkX), opts.linkX = false; end
if ~isfield(opts, 'pos') || isempty(opts.pos), opts.pos = [0.13 0.11 0.72 0.72]; end
if ~isfield(opts, 'linkTag') || isempty(opts.linkTag), opts.linkTag = 'plotTwoLink'; end

fig = opts.fig;
pos = opts.pos;     % leaves room for the top x-axis and title, by default

% ---- Axes 1 (bottom layer, white) ----
ax1 = axes('Parent', fig, 'Position', pos, 'Box', 'off', 'Color', 'w');
h1 = drawSet(ax1, c1);
% ---- Axes 2 (top layer, transparent) ----
ax2 = axes('Parent', fig, 'Position', pos, 'Box', 'off', 'Color', 'none');
h2 = drawSet(ax2, c2);

if opts.grid == 1
    grid(ax1, 'on');
elseif opts.grid == 2
    grid(ax2, 'on');
end

% keep the axes aligned on resize; store the link objects so they stay alive
hl = linkprop([ax1 ax2], {'Position', 'InnerPosition'});
setappdata(fig, opts.linkTag, hl);
if opts.linkX
    linkaxes([ax1 ax2], 'x');
end

if ~isempty(figTitle)
    % the title goes on the axes whose x-axis is at the top, so it sits
    % above that axis's tick labels and label
    if strcmp(c2.xAxis, 'top')
        title(ax2, figTitle);
    else
        title(ax1, figTitle);
    end
end

if ~isempty(opts.legendNames)
    % black proxy lines, one per line style, drawn with no data
    styles = c1.lineStyle;
    nNames = numel(opts.legendNames);
    hp = gobjects(1, nNames);
    for k = 1:nNames
        hp(k) = line(ax2, NaN, NaN, 'Color', 'k', ...
            'LineStyle', styles{min(k, numel(styles))}, 'LineWidth', c1.lineWidth);
    end
    lgd = legend(ax2, hp, opts.legendNames, 'Location', opts.legendLoc);
    if any(strcmpi(opts.legendLoc, {'northoutside', 'southoutside'}))
        lgd.Orientation = 'horizontal';
    end
elseif ~isempty(c1.name) || ~isempty(c2.name)
    legend(ax2, [h1(1) h2(1)], {c1.name, c2.name}, 'Location', opts.legendLoc);
end
end

function h = drawSet(ax, c)
%   draws every column of c.y on ax and sets up ax's axis locations,
%   colours, limits, labels and marker lines
set(ax, 'XAxisLocation', c.xAxis, 'YAxisLocation', c.yAxis, ...
    'XColor', c.axisColor, 'YColor', c.axisColor);
y = c.y;
if isvector(y), y = y(:); end
x = c.x;
if isvector(x), x = repmat(x(:), 1, size(y, 2)); end
nCurves = size(y, 2);
h = gobjects(1, nCurves);
for k = 1:nCurves
    h(k) = line(ax, x(:, k), y(:, k), 'Color', c.color{min(k, numel(c.color))}, ...
        'LineStyle', c.lineStyle{min(k, numel(c.lineStyle))}, 'LineWidth', c.lineWidth);
end
xlim(ax, c.xlim);  ylim(ax, c.ylim);
xlabel(ax, c.xlabel);  ylabel(ax, c.ylabel);
for xv = c.xlines(:).'
    line(ax, [xv xv], c.ylim, 'Color', c.axisColor, 'LineStyle', ':', 'LineWidth', 0.75);
end
for yv = c.ylines(:).'
    line(ax, c.xlim, [yv yv], 'Color', c.axisColor, 'LineStyle', ':', 'LineWidth', 0.75);
end
end

function c = setDefaults(c, col, xAx, yAx)
if ~isfield(c,'color')     || isempty(c.color),     c.color = col;     end
if ischar(c.color) || (isnumeric(c.color) && isvector(c.color))
    % one colour for both the axis identity (ticks/labels/marker lines)
    % and every curve -- exactly the previous behaviour
    c.axisColor = c.color;
    c.color = {c.color};
else
    % a cell of colours, one per curve: the axis keeps this set's own
    % identity colour -- the first curve's colour, which by convention is
    % the caller's usual single-filter colour for this set (e.g. 'b' for
    % zoom, 'r' for full) -- and curves are told apart by colour instead.
    % (Not `col`: that is plotTwo's own generic c1/c2 default ('r'/'b'),
    % which does not know which of zoom/full it was actually called for.)
    c.axisColor = c.color{1};
end
if ~isfield(c,'lineWidth') || isempty(c.lineWidth), c.lineWidth = 1.5; end
if ~isfield(c,'lineStyle') || isempty(c.lineStyle), c.lineStyle = {'-', '--', ':'}; end
if ischar(c.lineStyle), c.lineStyle = {c.lineStyle}; end
if ~isfield(c,'xAxis')     || isempty(c.xAxis),     c.xAxis = xAx;     end
if ~isfield(c,'yAxis')     || isempty(c.yAxis),     c.yAxis = yAx;     end
fin = @(v) v(isfinite(v));
if ~isfield(c,'xlim') || isempty(c.xlim)
    xs = fin(c.x(:));
    c.xlim = [min(xs) max(xs)];
end
if ~isfield(c,'ylim') || isempty(c.ylim)
    ys = fin(c.y(:));
    c.ylim = [min(ys) max(ys)];
    if diff(c.ylim) == 0, c.ylim = c.ylim + [-1 1]; end
end
if ~isfield(c,'xlabel'), c.xlabel = ''; end
if ~isfield(c,'ylabel'), c.ylabel = ''; end
if ~isfield(c,'name'),   c.name   = ''; end
if ~isfield(c,'xlines'), c.xlines = []; end
if ~isfield(c,'ylines'), c.ylines = []; end
end
