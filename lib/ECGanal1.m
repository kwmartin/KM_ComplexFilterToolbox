% Using IIR filters to condition ECG signal ready for peak detect

plt = 0;
N = 256;
% fls = [150:150];
fls = [1:6];
rcrds = [6:9];

control = 'Valvular_heart_disease';
%control = 'Healthy_control';
% control = 'Myocardial_infarction';
% control = 'Bundle_branch_block';
% control = 'Cardiomyopathy';
% control = 'Dysrhythmia';
% control = 'Heart_failure';
% control = 'Hypertrophy';
% control = 'Myocarditis';
% control = 'Valvular_heart_disease';

ecgDir = '/home/martin/Dropbox_old/Medical/database/ECG_mat_data/';

cntrlDIr = strcat(ecgDir,control);
flsLst = strcat(cntrlDIr,'.fls');
fid=fopen(flsLst);
tline = fgetl(fid);
files = cell(0,1);
while ischar(tline)
    files{end+1,1} = tline;
    tline = fgetl(fid);
end
fclose(fid);

fprintf('Number of files: %d\n',length(files));
files = files(fls);
for i = 1:length(files)
    matFile = strcat(cntrlDIr,'/',files{i});
    dataCells = load(matFile);
    [filepath,name,ext] = fileparts(files{i});
    data = zeros(15,N);
    k = 0;
    for j = rcrds
        k = k + 1;
        tic
        fNm = strcat('ECG_mat_data/',control,'/',name);
        [s1, fs, tm] = chngFs(fNm,j,250,1,28800);

        sigs = dsplyPlts(s1, files{i});
%         yst1 = fltrEcg(s1,0.1,0.25);
%         yst2 = abs(subSmpl(yst1,2));
%         yst3 = lpFltr5thOrdr(yst2,0.1875);
%         yst4 = subSmpl(yst3,4);
%         toc
%         corrs = autoCorr(yst4,1:64);
%         if plt == 1
%             % figure
%             % plot(yst3)
%             figure('Position',[100 200 600 600])
%             plot(corrs);
%             % ndB = plotFFT(yst4, [-60 5], 31.25);
%         end
%         
%         bf = bufClass([]);
%         % bf = bufClass(yst4(1:512));
%         nmbFrms = fix(length(yst4)/512);
%         accCrrs = [];
%         % figure
%         % plot(bf.corrs);
%         tic
%         % for k1 = 1:nmbFrms-1
%         for k1 = 1:nmbFrms
%             % for k2 = (k1*512 + 1):(k1 + 1)*512
%             for k2 = (k1 - 1)*512 + 1:k1*512
%                 crrs = bf.updBfr(k2, yst4(k2));
%             end
%             % crrs(2:end) = crrs(2:end)./crrs(1); % nomalizes to power of corrs(1)
%             % plot(crrs)
%             chkPrms(bf.pkBf, bf);
%             if length(bf.pkBf.strBfr) > 4096
%                 fprintf('store vector is getting too large\n');
%             end
%             accCrrs = [accCrrs; crrs];
%             a = 1;
%         end
%         toc
%         xvctr = 1:bf.pkBf.nmbPks;
%         figure('Position',[100 200 600 600])
%         plot(xvctr, accCrrs);
        b = 1;
    end
    % svFile = strcat(cntrlDIr,'/','spctrm_',name,'.mat');
    % save(svFile,'data');
    % outDat = struct(name, data);
    a = 1;
end
a=1;