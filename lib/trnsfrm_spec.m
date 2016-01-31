%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [wz, az] = trnsfrm_spec(ws,as,wp)
% Transform stopband specifications to mapped domain and order.
%
%   [wz az] = trnsfrm_spec(ws,as,w1,w2) is used to transform stopband specifications
%   to mapped domain and order. The passband is between w1 and w2, the specification
%   frequencies are in ws, and the corresponding specifications are in as. The mapped
%   frequencies are in wz, and the re-order specifications are in az.  
%

%   Ken Martin: 11/24/03
%   Revised:
%   Copyright 2003 Ken Martin 
%   $Revision: 0.01 $  $Date: 11/24/03

xx = sqrt((wp(2) - ws)./( wp(1) - ws));
[wz,i] = sort(xx);
az = as(i);