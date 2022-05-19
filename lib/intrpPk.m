function xPk = intrpPk(yVals,indx);
%   xPk = intrpPk(yVals,indx) uses quadratic interpolation of three points
%   with indx being the center point to find the x values of the peak with
%   improved accurach
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

    xPk = 0.5*(yVals(1) - yVals(3))/(yVals(1) - 2*yVals(2) + yVals(3));
    xPk = xPk + indx;
    a=1;
