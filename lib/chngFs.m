function [newSig, newFs, newTm] = chngFs(rcrdNm,rcrdNmb,newFs,strt,nmbSmpls)
%   reads a data record using rdsamp from a PysioNet database record
%   having the name recrdNm, changes its sample frequency from the original
%   to that specified by newFs, and returns [newSig, newFs, newTm]
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
    CrntDir = pwd();
    DbDir = '/home/martin/Dropbox_old/Medical/database';
    cd(DbDir);
    [sig, Fs, tm] = rdsamp(rcrdNm);
        
    cd(CrntDir);
    [P,Q] = rat(newFs/Fs);
    nsmpls = nmbSmpls*Q/P;
    if size(sig,2) > 1
        sig = sig(:,rcrdNmb);
    end
    if strt + nsmpls - 1 > length(sig)
        nsmpls = length(sig) - strt + 1;
    end
    sig2 = sig(strt:strt+nsmpls-1);
    newSig = resample(sig2,P,Q);
    newSig = newSig(:);
    newTm = (0:1/newFs:(length(newSig)-1)/newFs).';
    a = 1;