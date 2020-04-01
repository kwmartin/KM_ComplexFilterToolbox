RootDir = getenv('CMPLXROOT');
if isempty(RootDir)
    setenv('CMPLXROOT', cd);
    RootDir = getenv('CMPLXROOT');
end
% matlabpath(pathdef);
ExmplDir = strcat(RootDir, '/examples');
LibDir = strcat(RootDir, '/lib');
EcgDir = strcat(RootDir, '/ecg/mcode');
HRVASDir = strcat(RootDir, '/ecg/HRVAS');
PhyDir = strcat(RootDir, '/ecg/PhysioNet-Cardiovascular-Signal-Toolbox/');
addpath(LibDir);
addpath(ExmplDir);
addpath(EcgDir);
addpath(HRVASDir);
addpath(genpath(PhyDir));
% cd(strcat(RootDir, '/examples'));
% run /home/martin/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox/ecg/PhysioNet-Cardiovascular-Signal-Toolbox-1.0.2/startup

JuliaDir = strcat(RootDir, '/juliaFiles');
setenv('JULIASIMDIR', JuliaDir);
warning('off', 'Control:ltiobject:ZPKComplex')
warning('off', 'Control:ltiobject:TFComplex');
