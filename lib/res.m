function res(X0) % display poles and residue
% function res(X0) is a utility function for displaying poles and residues
% using Matlab's built in residue system, they are sorted in terms of 
% the imaginary parts
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
    [Ks Pls Rem] = getRes(X0);
    [Plsi Indx] = sort(imag(Pls));
    Pls = real(Pls(Indx)) + Plsi*j
    Ks = real(Ks(Indx))
    Rem
