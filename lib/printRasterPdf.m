function printRasterPdf(fHndl, filename, dpi)
% printRasterPdf(fHndl, filename, dpi)
% Print figure fHndl to <filename>.pdf as a rasterized image, instead of
% MATLAB's normal vector PDF output. dpi (default 150) sets the raster
% resolution.
%
% Use this instead of print(fHndl, filename, '-dpdf') for figures with
% very many overlaid data points (e.g. a Monte-Carlo trace overlay from
% runMcCscd/runMcCscd2), where a true vector PDF is inflated to several MB
% by the sheer number of path points. It also sidesteps a MATLAB
% limitation where, in a headless/-nodisplay session (as used by
% tools/run_all_examples.sh), OpenGL-based rasterization is unavailable
% for printing, so print(...,'-dpdf') - even with '-opengl', and even
% exportgraphics(...,'ContentType','image') - silently falls back to full
% vector output regardless of the requested renderer.
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

  if nargin < 3
    dpi = 150;
  end

  tmpPng = [tempname() '.png'];
  print(fHndl, tmpPng, '-dpng', ['-r' num2str(dpi)]);
  img = imread(tmpPng);
  delete(tmpPng);

  rH = figure('Visible', 'off');
  imshow(img);
  sz = size(img);
  set(rH, 'PaperUnits', 'inches');
  set(rH, 'PaperPosition', [0 0 sz(2)/dpi sz(1)/dpi]);
  set(rH, 'PaperSize', [sz(2)/dpi sz(1)/dpi]);
  print(rH, filename, '-dpdf');
  close(rH);
end
