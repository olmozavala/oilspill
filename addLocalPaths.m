function [inputFolder, outputFolder] = addLocalPaths()
% ADDLOCALPATHS Adds the necessary paths to your program
% This function should be different for each person and should
% not be added into the git repository

%atmInputFolder   = '/home/julio/Desktop/Oil_spill_simulator_v1/campos_de_velocidad/WRF_2010/';
%addpath(atmInputFolder)
%oceanInputFolder = '/home/julio/Desktop/Oil_spill_simulator_v1/campos_de_velocidad/HYCOM_2010_31p0/';
%addpath(oceanInputFolder)
%outputFolder = '/home/julio/Desktop/Oil_spill_v3/resultados/';

% Define the input folder (where the wind and current files are defined)
outputFolder = '/home/olmozavala/Desktop/PetroleoMatlab/salida/';
% Define the folder where the output will be stored
inputFolder = '/home/olmozavala/Desktop/PETROLEO_OUT/';

addpath(inputFolder) 
addpath('./lib') 
addpath('./lib/model') 
addpath('./lib/external') 

mkdir(outputFolder)
