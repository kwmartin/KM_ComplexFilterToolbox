function coeffs = calcSFG_Coeffs(elem1, elem2, elem3, G1, GF)
% calcSFG_Coeffs() is a helper program to convert from Lddr elems to parameters needed for an AC simulation
% of an SFG filter based a ladder having capacitors, with parallel imaginary reactances only. By using a helper
% program, the intent is to minimize errors encurred when using hand calculations. Note that except for the 
% first and last stage, G1, G2, and GF are zero, as all intermediate stages are reactive and do not dissipate power.
% For the first and last stages, G1, G2, and GF supply damping equivalent to RS and RL.
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

Csum = elem1.C + elem2.C + elem3.C;
fr = GF/Csum;
fq = imag(elem1.Y + elem2.Y + elem3.Y)/Csum;
fb = fr + j*fq;

yr1 = G1/Csum;
yq1 = imag(elem1.Y)/Csum;
y1 = yr1 + j*yq1;
c1 = elem1.C/Csum;

yr2 = 0;
yq2 = imag(elem3.Y)/Csum;
y2 = yr2 + j*yq2;
c2 = elem3.C/Csum;
coeffs = [c1, y1, c2, y2, fb];