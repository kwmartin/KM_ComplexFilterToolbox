function [L, X, C, Y] = calcLCXY2(k1, k2, P1, P2)
% [L, X, C, Y] = calcLCXY2(k1, k2, P1, P2) returns L, X, C, and Y
% assuming k1/(s - P1) + k2/(s- P2) as part on a complex removal
% of two loss poles at one time
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

wp1 = imag(P1);
wp2 = imag(P2);
C = 1/(k1 + k2);
XovrL = (-j)*(k1*wp2 + k2*wp1)/(k1 + k2);
YovrC = -(P1 + P2) - XovrL;
A = ((P1 + P2)/2)^2 - ((P1 - P2)/2)^2 - XovrL*YovrC;
%A = ((wp1 - wp2)/2)^2 - ((wp1 + wp2)/2)^2 - XovrL*YovrC;
L = 1/(C*A);
X = XovrL*L;
Y = YovrC*C;
if abs(X) < 5e-5
    X = 0;
end
if abs(Y) < 5e-5
    Y = 0;
end