function [inputFolder, outputFolder] = addLocalPaths()
% ADDLOCALPATHS Adds the necessary paths to your program
% This function should be different for each person and should
% not be added into the git repository

% Define the input folder (where the wind and current files are defined)
outputFolder = '/home/olmozavala/Desktop/PetroleoMatlab/salida/';
% Define the folder where the output will be stored
inputFolder = '/home/olmozavala/Desktop/PETROLEO_NEW';

addpath(inputFolder) 
addpath('./lib') 
addpath('./lib/model') 
addpath('./lib/external') 

mkdir(outputFolder)
