function hx = gd2yTrnsfrm(H,wp)
%   hx = gd2xTrnsfrm(h,wp) assumes the group delay of discrete-time H is due to poles only
%   (that is zeros are on jw circle), and transforms group-delay residues
%   to y domain. Note wp is passband specifed in Hz (that is between -0.5
%   and 0.5). The returned values in cell array hx are the group delay residues in the
%   y domain
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
    hp = H.p{1};
    N = length(hp);
    z = tf('z',1);
    for i = 1:N
        hpr{i} = z/(z - hp(i));
        hgdr{i} = zpk(0.5*(hpr{i} + hpr{i}')); % find real transfer functions
        hx{i} = xtrnsfrm(hgdr{i}, wp); % transform residue to y domain 
        % note we used to call it the x domain, we need to change a lot of
        % function names to clean up
        hx{i}.k = real(hx{i}.k);
        % we assume gain constant of residues has imaginary part equal to
        % zero
    end
    a=1;
