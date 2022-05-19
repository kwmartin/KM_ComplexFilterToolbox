function BPM = fndCorrBPM(corr, Fs);
%   BPM = fndCorrPk(corr) finds the peak of the autocorrelation function
%   and then returns the heart rate in beats per minute (BPM's).
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
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%

dffs = diff(corr);
sgns = sign(dffs);
indcs = 1 + find(diff(sgns) < 0);
indcs2 = indcs(11 < indcs & 52 > indcs);
pks = corr(indcs2);
[srtPks srtIndcs] = sort(pks, 'descend');
if length(srtPks) == 1
    pk = srtPks(1);
    indc = indcs2(srtIndcs(1));
elseif (srtPks(1) - srtPks(2)) > 0.15 && srtPks(1) > 0.45
    pk = srtPks(1);
    indc = indcs2(srtIndcs(1));
elseif (indcs2(srtIndcs(2)) > 1.4*indcs2(srtIndcs(1))) && srtPks(1) > 0.45
    pk = srtPks(1);
    indc = indcs2(srtIndcs(1));
elseif (indcs2(srtIndcs(1)) > 1.4*indcs2(srtIndcs(2))) && srtPks(2) > 0.45
    pk = srtPks(2);
    indc = indcs2(srtIndcs(2));
else
    pk = srtPks(1); % it didn't work but for now we need to return something
    indc = indcs2(srtIndcs(1));
    warning('Analyzing the auto-correlation to determine BPM failed');
end
xPk = intrpPk(corr(indc-1:indc+1),indc);
BPM = 60*Fs/xPk;
a=1;
