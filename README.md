%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

To see some examples of designing filters, start Matlab (Copyright, 1984-2016, The Mathworks Inc.),
change directory into ./examples, add ../lib to your path using
>>path('../lib',path)
and then either run the file design_examples.m, or run any of the individual exmpl?.m files

The programs in ./lib are intended for designing transfer functions for complex filters, both analog and digital.
The filters can have a single passband, and upper and lower stopbands that need not be symetrical.
The programs are highly based on the approach of Martin Snelgrove (see his unpublished paper in ./doc).
The programs and approach are described in greater detail in my 12 year old paper also in ./doc (unfortunately,
not well proofed; this is on my to-do list).
The programs were written in 2004, with a couple of bug fixes recently (mostly a fix for Matlab not
well supporting complex models and an extension to handle two fixed adjacent poles). It appears to me
(in 2016) that the equivalent routines have not become available in the intervening 12 years, so the
routines are being made publically available under the GPLv3 license. The routines do have bugs, and when
found, if you could e-mail me at martin@granitesemi.com, I will fix them as I find time. This may take
awhile, as complex filter design is currently not my day job; sending suggestions and/or code to fix the
bugs will speed up the process. Despite the bugs, the programs do seem to be highly accurate for most of
the design examples.

Some suggestions for extensions (perhaps for interested graduate students looking for a thesis topic) are:
1) extend to allow for multiple passbands (perhaps using N-path filters? Franks, L. E. , and I. W. Sandberg,
"An Alternative Approach to the Realization of Network Transfer Function: The N-Path Filter. Journal,
September 1960. The Bell System Technical)

2) Extend so digital filters are designed directly without using the bilinear transform. I'm hoping to some
day get to this using an LDI like approach where the design is done using zp = z^(1/2) - z^(-1/2) as the
frequency variable, and then at the end transforming back to the normal z^(-1) variable; maybe you could beat
me to it?

3) Extend so phase equalization is included.

4) Fix the Matlab (Copyright, 1984-2016, The Mathworks Inc.) model toolboxes to properly handle complex coefficients.

5) Extend to the muliple-in multiple-out case (this would be really interesting but could be difficult).

6) Extend to adaptive filters where the poles are automatically moved to reject interferers while the exact
design of the passbands are preserved; I don't think this would be too difficult for say one or two poles,
and could be real useful for wireless front ends. Basically having the filter approximations routines running
in the background during actual system operation could take advantage of cheap (Beaglebone Black?) computers.
This type of approach (and others like it) strikes me as a whole new methodology that was not previously available

Just some thoughts; I do find playing with Matlab (Copyright, 1984-2016, The Mathworks Inc.) and complex
filters to be an enjoyable passtime; perhaps you'll find this to be true as well.

-Ken Martin, originally 2004, now 2016.
