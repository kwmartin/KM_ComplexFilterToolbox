function H2 = freq_shift(H, delta_w)
% FREQ_SHIFT(H) is used to frequency shift a transfer function
% specified by the H system tf or zpk object. delat_w will normally be imaginary
% and is in rad. The scaling is done by shifting the poles and zeros.
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
    if imag(delta_w) < 1e-5 delta_w = delta_w*j; end % assume delta_w is real
    switch class(H)
        case 'zpk'
            [z,p,k] = zpkdata(H, 'v');
            p2 = p + delta_w;
            z2 = z + delta_w;
            H2 = zpk(z2, p2, k);
        case 'tf'
            [z,p,k] = zpkdata(H, 'v');
            p2 = p + delta_w;
            z2 = z + delta_w;
            H2 =zpk(z2, p2, k);
            H2 = tf(H2);
        case 'double'
            H2 = H + delta_w;
    end
