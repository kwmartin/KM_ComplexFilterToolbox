function X = chooseTF(X1o, X1s, X2o, X2s, indic)
%   X = chooseTF(X1o, X1s, X2o, X2s, indic) is just a simple function
%   to save having to add a case statement; indic should be set by
%   mkXsCmplx2() before calling chooseTF()
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin
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

    if indic == 1
      X = X1o;
    elseif indic == 2
      X = X1s;
    elseif indic == 3
      X = X2o;
    elseif indic == 4
      X = X2s;
    end
