function Xfb2 = fndInitXfb1(Xfbe,xine)
%   Xfbi = fndInitXfb1(Xfbe,xine) finds the initial values required for
%   complex resonator outputs when switching directions
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
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

    kXfb = abs(Xfbe);
    phXfb1 = angle(Xfbe);
    phXin = angle(xine);
    phXfb2 = 2*phXin - phXfb1;
    Xfb2 = kXfb.*exp(j*phXfb2);
    a = 1;
