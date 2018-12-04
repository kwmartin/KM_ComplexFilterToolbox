function [margin, smin] = disp_margin(sys,ws,as,wp,e_,type)
% [margin, smin] = disp_margin(sys,ws,as,wp,e_,type) print stop-band margin
% Finds the differences between the stopband loss and the interpolated specs
% at the frequncies specified by the vector w. As should be in dB. The
% specification frequencies are in the transformed domain.
%
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
zmin = find_minima(sys,ws,as,wp); % find the minima of the stop-band loss
[wsz As] = trnsfrm_spec(ws,as,wp);
ns = length(ws);
zmin = [wsz(1) zmin wsz(ns)];
[smin,indx] = sort(-j*z2s(zmin,wp).');
margin = find_margin(sys,ws,as,wp,e_,zmin(indx));
display('Minima and Stopband Edge Frequencies');
if (nargin == 6) & strcmp(type ,'discrete')
    smin = atan(smin./2)./pi;
end
smin
format long;
display('Stopband Margins');
10*margin
