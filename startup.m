RootDir = getenv('CMPLXROOT');
if isempty(RootDir)
    setenv('CMPLXROOT', cd);
    RootDir = getenv('CMPLXROOT');
end
ExmplDir = strcat(RootDir, '/examples');
LibDir = strcat(RootDir, '/lib');
cd(strcat(RootDir, '/examples'));
path(LibDir,path);
path(ExmplDir,path);
warning('off', 'Control:ltiobject:ZPKComplex')
warning('off', 'Control:ltiobject:TFComplex');
