function addLocalPaths(atmInputFolder,oceanInputFolder,output_dir)
% ADDLOCALPATHS Adds the necessary paths to your program
% This function should be different for each person and should
% not be added into the git repository
addpath(atmInputFolder)
addpath(oceanInputFolder)
addpath('./lib')
addpath('./lib/model')
addpath('./lib/external')
mkdir(output_dir)
end