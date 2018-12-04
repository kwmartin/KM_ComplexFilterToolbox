function H2 = freqScale(H, scaleFctr)
% freqScale is used to scale a continous time Transfer function in s
% relative to dc. A scaleFctr larger than 1 scales the filter to larger frequencies
% for example, for a low-pass between -1 and 1 rad., a sclFctr of 2 changes the
% passband to be between -2 and 2 and the stop-band frequencies proportionately
% an equivalent function based on scaling using a state-space filter is scaleFltr()
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
    switch class(H)
        case 'zpk'
            [z,p,k] = zpkdata(H, 'v');
            p2 = p*scaleFctr;
            z2 = z*scaleFctr;
            M = length(z) - length(p);
            k = k/scaleFctr^M;
            H2 = zpk(z2, p2, k);
        case 'tf'
            [z,p,k] = zpkdata(H, 'v');
            p2 = p*scaleFctr;
            z2 = z*scaleFctr;
            H2 = zpk(z2, p2, k);
            M = length(z) - length(p);
            k = k/scaleFctr^M;
            H2 = tf(H2);
    end
