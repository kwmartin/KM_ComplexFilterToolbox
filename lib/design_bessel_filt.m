function H = design_bessel_filt(ni,wp,ap)
%   H = design_bessel_filt(ni,wp,ap) designs a Bessel filter having attenuation
%   ap (in dB) at the passband edges defined by wp. The order of the filter is
%   equal to the number of infinite loss poles specified by ni
%   First, a symmetric low-pass is designed to have 1s delay at dc. This is
%   analyzed to find the positive frequency where the gain is Ap. The filter is
%   frequency scaled to have the specified pass-band width. Finally, it is frequency
%   shifted to the specified passband frequencies. For this early version, finite
%   loss-poles are not supported, the response is symmetric about the pass-band.
%   The plan is to relax these restrictions in the future.
%
%   Ken Martin: 11/24/03
%   Revised: 10/20/18
%   $Revision: 0.01 $  $Date: 11/24/03
%
%   For detailed explanation see:
%   K. Martin, “Approximation of complex iir bandpass filters without arith-
%   metic symmetry,” IEEE Trans. Circuits and Systems I, vol. 52, pp. 794–
%   803, April 2005.
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
% The control toolbox is giving too many warnings with complex sys objects
% this tool-box looks after the fact Matlab does not support complex systems
warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

if nargin ~= 3
    error('There should be 3 inputs: ni (number of poles at infinity), wp (pass-band frequencies), ap (pass-band atten.)');
end

H1 = BesselFltr(ni);
w = 1;
ep = -ap*log(10)/20; % desired loss in nepers
for i = 1:10
    [lgH, phH, gdH, dLdW, dTdW] = AnlzH(H1, w);
    w = w - (lgH - ep)./dLdW;
end

H2 = scaleFltr(H1, 0.5*diff(wp)/w);
wShft = mean(wp);
H = freq_shift(H2, wShft);

warning on all
