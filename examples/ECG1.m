% a 256 channel filter-bank simulation based on monotonic filters having 4
% movable loss-poles

N = 256;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.2 -0.1 0.1 0.2]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -delta_f/2; % lower passband edge
wp(2) = delta_f/2; % upper passband edge
ws = [-0.49 -1.0*delta_f 1.0*delta_f 0.49];
as = [50 50 50 50];
Ap = 3.6; % the passband ripple in dB
px = [];
ONE_STP = 0;

H1 = dsgnDigitalFltr(p, px, ni, wp, ws, as, Ap, 'monotonic');
plot_drsps(H1, wp, 'b', [-60 1]);
cscdFltr1 = mkCscdFltrD(H1, wp);
%cscdFltr1.plotGn(wp, ws, -100, 2);
xin = zeros(8192,1);
xin(1) = 1;
ylim = [-60 2];

tic
Out = simCscdFltrBnk(cscdFltr1, xin, delta_f);
toc

tic
hndl = figure('Position',[800 100 600 600]);
[ax1 ax2, f, ymRef] = plotRspns(Out(:,1), [-0.05 0.1], 'b', ylim);
hold(ax1, 'on');
hold(ax2, 'on');
sum = Out(:,1);
for i = 2:N
    plotRspns(Out(:,i), [-0.5 0.5], 'b', ylim);
    sum = sum + Out(:,i);
end
plotRspns(sum, [-0.5 0.5], 'r', ylim);
toc

[zlp, plp, klp] = ellip(8,0.01,60,0.2);
hlp = zpk(zlp,plp,klp,1);
cscdLP = mkCscdFltrD(hlp, [-0.1 0.1]);
[zhp,php,khp,AllpassNum,AllpassDen] = zpklp2hp(zlp,plp,klp,0.2,0.004);
hhp = zpk(zhp,php,khp,1);
cscdHP = mkCscdFltrD(hhp, [-0.004 0.004]);

control = 'Healthy_control';

ecgDir = '/home/martin/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox/ecg/ECG_mat_data/';
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
% if length(files) > 10
%     files = files(1:10);
% end
clear sum;
% figure
% hold on
files = files(1);
for i = 1:length(files)
    matFile = strcat(cntrlDIr,'/',files{i});
    dataCells = load(matFile);
    [filepath,name,ext] = fileparts(files{i});
    data = zeros(15,N);
    for i = 1:15
        tic
        inData = dataCells.val(i,:).';
        y = anlyzData(inData,cscdLP,cscdHP,cscdFltr1,delta_f);
        data(i,:) = y;
        toc
        % figure
        % plot(y)
    end
    svFile = strcat(cntrlDIr,'/','spctrm_',name,'.mat');
    save(svFile,'data');
    % outDat = struct(name, data);
end
a=1;