function xout = runJuliaSim(rcrd,JuliaDir)
%   sends xin to the juliaFiles directory, uses Julia to filter the data,
%   loads the output from the julia simulation back into the workspace
%
%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2020  Kenneth Martin
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without1 even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

    tic
    dat = getData(rcrd, 256);
    outFile = strcat(JuliaDir, '/xinFile');
    % dat = dat + 1.0j.*ones(length(data),1).*eps;
    data(:,1) = dat;
    data(:,2) = zeros(length(dat),1);
    save(outFile,'data');
    command = strcat(['julia ', JuliaDir, '/runFilt.jl']);
    [status,cmdout] = system(command);
    status
    inFile = strcat(JuliaDir, '/filtOut');
    strctin = load(inFile);
    xout = strctin.data;
    toc
    a = 1;