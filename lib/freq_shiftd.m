function H2 = freq_shiftd(H, delta_f)
% FREQ_SHIFT(H) is used to frequency shift a transfer function
% specified by the H system tf or zpk object. delat_w will normally be real
% and is in Hz The scaling is done by shifting the poles and zeros of a
% zpk system object and then adjust k appropriately
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
    if imag(delta_f) > 1e-5 delta_f = imag(delta_f); end % assume delta_f is imaginary
    switch class(H)
        case 'zpk'
            [z,p,k,T] = zpkdata(H, 'v');
            eshft = exp(j*2*pi*delta_f*T);
            p2 = p*eshft;
            z2 = z*eshft;
            M = length(z) - length(p);
            k = k*eshft^M;
            H2 = zpk(z2, p2, k, T);
        case 'tf'
            [z,p,k,T] = zpkdata(H, 'v');
            T = H.Ts;
            eshft = exp(-j*2*pi*delta_f*T);
            p2 = p*eshft;
            z2 = z*eshft;
            M = length(z) - length(p);
            k = k*eshft^M;
            H2 = zpk(z2, p2, k, T);
            H2 = tf(H2);
    end
