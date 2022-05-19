function hx = xtrnsfrm(h,wp)
%   hx = xtrnsfrm(h,wp) transforms a discrete-time model in the x domain
%   to the continuous-time x domain using a conformal transform and plots
%   the magnitude response
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

    warning('off', 'Control:ltiobject:TFComplex');
    warning('off', 'Control:ltiobject:ZPKComplex');

    f = -0.5:1e-4:0.5;
    w = 2*pi*f;
    s_ = j*w;
    % [hdB, h_] = log_rspsd(h,s_);
    % h_(1)=h_(2);
    % h_(end)=h_(end-1);
    % figure
    % plot(f,abs(h_),'LineWidth',2);
    % figure
    % plot(f,(180/pi)*unwrap(angle(h_)),'LineWidth',2);

    wpx = 2*tan(wp*pi);
    hx = trnsfrmH2x(h,wpx);
    hwp1 = rspsd(h, j*2*pi*wp(1));
    hwp2 = rspsd(h, j*2*pi*wp(2));
    hx.K = hwp1;
    hx1_ = rsps(hx,j*1e6);
    hx2_ = rsps(hx,j*0);
    % wx = (0:1e-4:10);
    % hx_ = rsps(hx,j*wx);
    % figure;
    % plot(wx,abs(hx_));
    % figure;
    % plot(wx,angle(hx_)*(180/pi));
    a=1;
