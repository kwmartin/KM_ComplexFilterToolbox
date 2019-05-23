fileID = fopen('/home/martin/go/src/github.com/kw_martin/rdFltr1/fltrc.dat','r');
A = textscan(fileID,'%s');
fclose(fileID);
B = str2double(A{1});
C = reshape(B, 64, 8192).';
Out = C;
N=64;
ylim = [-110,2];
hndl = figure('Position',[500 100 800 800]);
[ax1 ax2, f, ymRef] = plotRspns(Out(:,1), [-0.05 0.1], 'b', ylim);
hold(ax1, 'on');
hold(ax2, 'on');
sum = Out(:,1);
for i = 2:N
    plotRspns(Out(:,i), [-0.5 0.5], 'b', ylim);
    if (i~= 32)
        sum = sum + Out(:,i);
    end
end
plotRspns(sum, [-0.5 0.5], 'r', ylim);
