function m10 = find_margin2d(sys,ws,as,wp,w)
%   m10 = find_margin2d(sys,ws,as,wp,w) finds stop-band margins in z
%   find_the differences between the stopband loss
%   and the interpolated specs at the frequencies specified by the vector w. As
%   should be in dB. The specification are interpolated in th none-trasformed
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

ww = z2wd(w,wp);
indx = (ww < -pi);
ww(indx) = -pi;
indx = (ww > pi);
ww(indx) = pi;
a10 = (interp1(2.*pi.*ws, as, ww).')./10;
h10 = log10(10.^log_rsps(sys*sys',w) + 1);
m10 = h10 - a10;