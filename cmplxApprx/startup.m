RootDir = getenv('CMPLXROOT');
if isempty(RootDir)
    setenv('CMPLXROOT', '/home/Dropbox/Matlab/KM_ComplexFilterToolbox/');
    RootDir = getenv('CMPLXROOT');
end
ExmplDir = strcat(RootDir, '/examples');
LibDir = strcat(RootDir, '/lib');
cd(strcat(RootDir, '/examples'));
path(LibDir,path);
path(ExmplDir,path);
addpath('/home/Dropbox/Matlab/lib');
warning('off', 'Control:ltiobject:ZPKComplex');
warning('off', 'Control:ltiobject:TFComplex');
