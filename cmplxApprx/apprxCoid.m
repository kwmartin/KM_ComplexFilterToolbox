function [apprxOid, noise, stdErr] = apprxCoid(freq, iDat)
%   [apprxOid, noise, stdErr] = apprxCoid(freq, data) matches an ideal coplexoid to data
%   frame by frame, and returns the matched complexoid and data after removing
%   the complexoid to make spur analysis more accurate
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
    iN = length(iDat);
    iT = 1/freq;
    npts = iT*2;
    nFrames = floor(iN/iT);

    dwT = 2*pi*freq;
    npts = iT*2;
    freqPts = (0:dwT:dwT*(npts - 1))';
    ejwT = exp(j*(dwT:dwT:dwT*iT)).';

    cs_ = cos(freqPts);
    sn_ = sin(freqPts);

    apprxOid = [];
    noise = [];
    stdErr = [];
    for iFrm = 0:nFrames-2
        iIn = iFrm*iT+1:(iFrm+2)*iT;
        if iIn(end) > 20493
            a = 0;
        end
        iSmpl=iDat(iIn);
        [P, N] = filterPN(freq, iSmpl);
        apprxSmpl = P.*ejwT;
        apprxOid = [apprxOid; apprxSmpl];
        errSmpl = apprxSmpl - iSmpl(1:iT);
        noise = [noise; errSmpl];
        stdE = std(errSmpl);
        stdErr = [stdErr; stdE];
        oldApprx = apprxSmpl;
        oldSmpl = iSmpl;
        a = 1;
    end

    a = 1;
    