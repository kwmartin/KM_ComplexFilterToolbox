function savePaperFig(fig, file, widthIn, heightIn, fontSize)
%   savePaperFig(fig, file, widthIn, heightIn, fontSize) exports fig for
%   the paper: file.pdf (vector, for the pdflatex build) and file.png
%   (300 dpi, for the HTML build). file has no extension; its folder is
%   created if needed.
%
%   The figure is resized to widthIn x heightIn inches (default 3.5 x 2.8,
%   one conference column) and every axes and legend gets fontSize points
%   (default 8). The axes are then refitted to the figure using their
%   TightInset, so tick labels and axis labels on all four sides (as
%   plotTwo produces) are not cut off. The on-screen figure keeps the new
%   size.
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

  if nargin < 3 || isempty(widthIn), widthIn = 3.5; end
  if nargin < 4 || isempty(heightIn), heightIn = 2.8; end
  if nargin < 5 || isempty(fontSize), fontSize = 8; end

  set(fig, 'Units', 'inches');
  p = get(fig, 'Position');
  set(fig, 'Position', [p(1) p(2) widthIn heightIn]);
  ax = findall(fig, 'Type', 'axes');
  set(ax, 'FontSize', fontSize);
  lg = findall(fig, 'Type', 'legend');
  set(lg, 'FontSize', fontSize);
  for a = ax(:).'
    set(get(a, 'Title'), 'FontSize', fontSize);
  end
  % screen line widths (1.5) are too heavy at column width
  ln = findall(fig, 'Type', 'line');
  for h = ln(:).'
    if get(h, 'LineWidth') > 1
      set(h, 'LineWidth', 1);
    end
  end

  % refit: the union of every axes' TightInset (normalized units) is the
  % margin needed on each side, plus a small gap
  drawnow;
  set(ax, 'Units', 'normalized');
  ti = zeros(numel(ax), 4);
  for i = 1:numel(ax)
    ti(i, :) = get(ax(i), 'TightInset');
  end
  m = max(ti, [], 1) + 0.01;
  % a legend outside the axes (below or above) needs its own strip
  for l = lg(:).'
    set(l, 'Units', 'normalized');
    lp = get(l, 'Position');
    if strcmpi(get(l, 'Location'), 'southoutside')
      m(2) = m(2) + lp(4) + 0.01;
    elseif strcmpi(get(l, 'Location'), 'northoutside')
      m(4) = m(4) + lp(4) + 0.01;
    end
  end
  newPos = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4)];
  set(ax, 'Position', newPos);
  % put an outside legend in its strip, centred under (or over) the axes
  drawnow;
  for l = lg(:).'
    lp = get(l, 'Position');
    xc = newPos(1) + newPos(3)/2 - lp(3)/2;
    if strcmpi(get(l, 'Location'), 'southoutside')
      set(l, 'Position', [xc, 0.005, lp(3), lp(4)]);
    elseif strcmpi(get(l, 'Location'), 'northoutside')
      set(l, 'Position', [xc, 1 - lp(4) - 0.005, lp(3), lp(4)]);
    end
  end

  folder = fileparts(file);
  if ~isempty(folder) && ~exist(folder, 'dir')
    mkdir(folder);
  end
  exportgraphics(fig, [file '.pdf'], 'ContentType', 'vector');
  exportgraphics(fig, [file '.png'], 'Resolution', 300);
end
