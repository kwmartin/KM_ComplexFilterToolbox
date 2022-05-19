function sens = sensGxi(zrs,w)
% sens = sensGxi(zrs,w) finds the sensitivity of a product of (s - zi) wrt
% w of s=jw
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
    warning('off', 'Control:ltiobject:TFComplex');
    warning('off', 'Control:ltiobject:ZPKComplex');
    
    N = length(zrs);
    zrs = zrs(:); % just in case not in a column)
    trms = j*w*ones(size(zrs)) - zrs;
    trm1 = sum(log(trms));
    trm2 = prod(trms);
    trm3 = 0;
    for i = 1:N
        trm3 = trm3 + 1/trms(i);
    end
    trm3 = trm3*j;
    sens = trm1*trm2*trm3;
    a=1;
