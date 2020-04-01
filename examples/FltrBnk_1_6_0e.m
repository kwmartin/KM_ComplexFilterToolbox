% a 64 channel filter-bank simulation based on monotonic filters having 4
% movable loss-poles

fltrNm = 'FltrBnk_1_6_0e';
RootDir = getenv('CMPLXROOT');
if isempty(RootDir)
    setenv('CMPLXROOT', '/home/martin/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox');
end
N = 64;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.3 -0.2 -0.1 0.1 0.2 0.3]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
fp = []; ws = [];
fp(1) = -delta_f/2; % lower passband edge
fp(2) = delta_f/2; % upper passband edge
ws = 2*pi*[-0.49 -delta_f delta_f 0.49];
as = [50 50 50 50];
Ap = 0.3; % the passband ripple in dB
px = [];
ONE_STP = 0;
wp = 2*tan(pi*fp);

% cscdFltr1 = dsgnCascadeFltr2(p,px,ni,wp,ws,as,Ap,'elliptic');
H = design_dig_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
plot_drsps(H, fp, 'b', [-120 1]);
cscdFltr1 = mkCscdFltrD2(H, wp);

H1 = cscdFltr1.getSystem();
plot_drsps(H1, fp, 'b', [-120 1]);
%cscdFltr1.plotGn(fp, ws, -100, 2);

cscd2Yml(cscdFltr1, strcat(RootDir, '/examples/', fltrNm, '.yml'));

xin = zeros(8192,1);
xin(1) = 1;
ylim = [-120 2];

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
    if (i~= 40)
        sum = sum + Out(:,i);
    end
end
plotRspns(sum, [-0.5 0.5], 'r', ylim);
toc

% Out2 = parseOut(64);
% tic
% hndl2 = figure('Position',[800 100 600 600]);
% [ax3 ax4, f, ymRef] = plotRspns(Out2(:,1), [-0.05 0.1], 'b', ylim);
% hold(ax3, 'on');
% hold(ax4, 'on');
% sum = Out(:,1);
% for i = 2:N
%     plotRspns(Out2(:,i), [-0.5 0.5], 'b', ylim);
%     if (i~= 40)
%         sum = sum + Out2(:,i);
%     end
% end
% plotRspns(sum, [-0.5 0.5], 'r', ylim);
% toc

% drawnow;
% cscdHndl = gcf;
% print(strcat('../examples/Figures/', fltrNm), '-dpng');

 a=1;