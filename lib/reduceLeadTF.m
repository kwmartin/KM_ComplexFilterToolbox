function Tf2 = reduceLeadTf(Tf1, tol)
%   Tf2 = reduceLeadTf(Tf1, tol) deletes leading zeros of a polynomial
%   in transfer function form as oposed to zero form
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

    if nargin < 2
        tol =  1e-6;
    end

    ind = find(abs(Tf1) > tol);
    if ~isempty(ind)
        Tf2 = Tf1(ind(1):end);
    else
        Tf2 = [];
    end