RootDir = getenv('CMPLXROOT');
if isempty(RootDir)
    setenv('CMPLXROOT', cd);
    RootDir = getenv('CMPLXROOT');
end
% matlabpath(pathdef);
ExmplDir = strcat(RootDir, '/examples');
LibDir = strcat(RootDir, '/lib');
EcgDir = '/home/martin/Medical/database/ECG_mat_data/';
% HRVASDir = '/home/martin/Medical/HRVAS';
% PhyDir = '/home/martin/Medical/PhysioNet-Cardiovascular-Signal-Toolbox';
restoredefaultpath;
addpath(LibDir);
addpath(ExmplDir);
addpath(EcgDir);
% pathdef
% addpath(HRVASDir);
% addpath(genpath(PhyDir));
% cd(strcat(RootDir, '/examples'));
% run /home/martin/Matlab/Complex/KM_ComplexFilterToolbox/ecg/PhysioNet-Cardiovascular-Signal-Toolbox-1.0.2/startup

JuliaDir = strcat(RootDir, '/juliaFiles');
setenv('JULIASIMDIR', JuliaDir);
warning('off', 'Control:ltiobject:ZPKComplex')
warning('off', 'Control:ltiobject:TFComplex');
