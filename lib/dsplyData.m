function fileMap = dsplyData(control,rcrds,ecgs,type_)
%   fileMap = dsplyData(control,rcrds,ecgs,type_) is used to display ECG plots
%   control is a string specifying the control group, rcrd#s is a list of
%   of the indices of the ecg groups, ecg#s is a list of the ecgs in each
%   group (there 1-15 ecgs for each set but usually only first 12 are
%   displayed. fileMap is returned that is a map from the name to the line
%   number of the flsLst
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
    ecgDir = '/home/martin/Dropbox_old/Matlab/Complex/KM_ComplexFilterToolbox/ecg/ECG_mat_data/';
    cntrlDIr = strcat(ecgDir,control);
    flsLst = strcat(cntrlDIr,'.fls');
    fid=fopen(flsLst);
    tline = fgetl(fid);
    files0 = cell(0,1);
    while ischar(tline)
        files0{end+1,1} = tline;
        tline = fgetl(fid);
    end
    fclose(fid);
    fileMap = containers.Map;
    for i = 1:length(files0)
        [filepath,name,ext] = fileparts(files0{i});
        fileMap(name) = i;
    end

    files = files0(rcrds);
    names = {};
    for i = 1:length(files)
        [filepath,name,ext] = fileparts(files{i});
        names{i} = name;
        if strcmp(type_,'spctrm')
            ldFile = strcat(cntrlDIr,'/','spctrm_',name,'.mat');
            inData = load(ldFile);
            data = inData.data(:,256:384);
        elseif strcmp(type_,'ecg')
            matFile = strcat(cntrlDIr,'/',files{i});
            ECGdat = load(matFile);
            data = ECGdat.val;
        end
        fig = figure('Position',[200 60 1600 900]);
        indxs = [1 5 9 2 6 10 3 7 11 4 8 12];
        axs = zeros(1, 12);
        for j = 1:length(ecgs)
            axs(j) = subplot(3, 4, indxs(j));
            plot(data(ecgs(j),:));
            if strcmp(type_,'spctrm')
                axis([0 128 0 4000000])
            end
            title(strcat(name, '  Record #',int2str(ecgs(j))), 'FontSize', 8, 'Interpreter','none');
        end
    end
        
    
    a = 1;