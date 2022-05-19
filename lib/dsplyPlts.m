function sigs = dsplyPlts(ecg, patientNm)
%   dsplyPlts(ecg,bfr,crrs) analyzes and shows plots for the ecg signal
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

    Ts = 0.032; % sample time of yst4, 1/(125Hz decimated by 4)
    Fs = 1/Ts;

    width = 1600;
    height = 800;
    fig = figure('Position',[20 400 width height]);
    title(patientNm);
    fH = 0.4;
    fSpc = 0.025;
    fW = (1 - 5*fSpc)/3;
    fY1 = 0.52;
    fY2 = 0.05;
    fX = @(k) (k*fSpc + (k-1)*fW);
    
    tic
    yst1 = fltrEcg(ecg,0.1,0.25);
    % throw away initial transient
    yst1 = yst1(129:end);
    yst2 = abs(subSmpl(yst1,2));
    yst3 = lpFltr5thOrdr(yst2,0.1875);
    yst4 = subSmpl(yst3,4);
    toc
    tic
    bf = bufClass([]);
    nmbFrms = fix(length(yst4)/512);
    accCrrs = [];
    initPk = max(yst4(1:128))';
    bf.gain = 1.0/initPk;
    bf.mxValue = 1.0;
    BPM1 = 0;
    for k1 = 1:nmbFrms
        for k2 = (k1 - 1)*512 + 1:k1*512
            crrs = bf.updBfr(k2, yst4(k2));
        end
        accCrrs = [accCrrs; crrs];
        BPM = fndCorrBPM(crrs, Fs);
        BPM1 = BPM1 + BPM;
        bf.pkBf.chkPrms(bf, round(Fs*60/BPM));
        bf.pkBf.rmvPks(bf, round(Fs*60/BPM));
        a = 1;
    end
    BPM1 = BPM1/nmbFrms;
    toc

    ax1 = subplot('position',[fX(1) fY1 fW fH]);
    plot(ecg)
    title('ECG Data')

    ax2 = subplot('position',[fX(2) fY1 fW fH]);
    yst4Mx = max(yst4);
    plot(yst4./yst4Mx);
    title('Filtered Power');
    axis([0 ceil(length(yst4)/100)*100 0 1.1]);

    ax3 = subplot('position',[fX(3) fY1 fW fH]);
    %xvctr = 1:bf.pkBf.nmbPks;
    indcs = 1:48;
    xvctr = (indcs - 1).*0.032;
    plot(xvctr,accCrrs(:,indcs));
    title('Power Auto-Correlation');
    axis([0  xvctr(end) 0 1.2]);

    ax4 = subplot('position',[fX(1) fY2 fW fH]);
    diffs = bf.pkBf.getDiffs();
    diffs = diffs(2:end).';
    mdiffs = mdFlt(diffs);
    mdiffs = mdiffs(:).';
    xvctr = 1:length(diffs);
    plot(xvctr,[diffs; mdiffs]);
    title('Periods and Filtered Periods');
    axis([1  xvctr(end) 10 60]);
    BPM2 = 60*Fs/(mean(mdiffs));
    ax5 = subplot('position',[fX(2) fY2 fW fH]);
    [f ndB] = nFFT(yst4, Fs);
    plot(f, ndB)
    axis([-Fs/2  Fs/2 -80 5]);
    title('FFT of Filtered Power');

    ax6 = subplot('position',[fX(3) fY2 fW fH]);
    pos = get(ax6,'Position');
    un = get(ax6,'Units');
    delete(ax6);
    ht = uitable('Units',un,'Position',pos);
    hr1 = sprintf('%.1f',BPM1);
    hr2 = sprintf('%.1f',BPM2);
    ht.Data = {'', '', '';'', 'Heart Rate1:', hr1;'', 'Heart Rate2:', hr2};
    ht.RowStriping = 'off';
    % ht.ColumnStriping = 'off';
    ht.ColumnName = {};
    ht.RowName = {};
    ht.FontSize = 12;
    ht.ColumnWidth = {20, 120, 60};
    ht.FontWeight = 'bold';

    text(-5.5, 115, patientNm, 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
    % ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
    % text(0.435, 0.97, patientNm, 'FontSize', 14, 'FontWeight', 'bold')
    % currentFigure = gcf;
    % title(currentFigure.Children(end), patientNm);
    
    sigs.pwr = yst4;
    sigs.crrs = accCrrs;
    sigs.strBfr = bf.pkBf.strBfr;
    sigs.pkBfr = bf.pkBf;
    sigs.bf = bf;
    a = 1;
