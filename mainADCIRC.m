% Oil spill v.2
% Lagrangian algorithm to simulate oil spills in the Gulf of Mexico
close all; clear; clc; format compact
tic()
%--- Edit addLocalPaths.m to address your input and output directories ---%
outputFolder = addLocalPaths();
modelConfig = ModelConfig;
modelConfig.outputFolder = outputFolder;
%---------------------------- Spill location -----------------------------%
modelConfig.lat =  19.1965;
modelConfig.lon = -96.08;
%----------------------- Spill timing (yyyy,mm,dd) -----------------------%
modelConfig.startDate = datetime(2010,04,23);
modelConfig.endDate   = datetime(2010,04,28);
%hycom | adcirc--------- Model Type--------------- -----------------------%
modelConfig.model              = 'adcirc';
%---------------- Oil barrels representing one particle ------------------%
modelConfig.barrelsPerParticle = 100;
%----------------------- Lagrangian time step (h) ------------------------%
modelConfig.timeStep = 1;
%--------------------------- Simulation depths ---------------------------%
modelConfig.depths = [0]; % First index MUST be 0 (surface)
%------------------- Oil classes proportions per depth -------------------%
modelConfig.components = [...
    [.1 .1 .1 .1 .1 .1 .1 .3];
    ];
modelConfig.totComponents = length(modelConfig.components(1,:));
%------------------ Initial spill radius (m) per depth -------------------%
%------------- 2 STD for random initialization of particles --------------%
modelConfig.diffusion = [.05];
%--------------- Turbulent-diffusion parameter per depth -----------------%
modelConfig.turbulentDiff = [1];
%------ Wind fraction used to advect particles (only for 0 m depth) ------%
modelConfig.windcontrib = 0.035;
%--------------- Distribution of oil per subsurface depth ----------------%
modelConfig.subSurfaceFraction = [1];
%------------------------------ Oil decay --------------------------------%
modelConfig.decay.evaporate       = 1;
modelConfig.decay.collected       = 1;
modelConfig.decay.burned          = 1;
modelConfig.decay.burned_radius   = 3; % Burning radius in km
modelConfig.decay.exp_degradation = 1; % Exponential degradation
% Exponential degradation parameters:
exp_deg_Percentage = 95;
exp_deg_Days       = [3, 6, 9, 12, 15, 18, 21, 24];
[thresholds,dailyDecayRates] = threshold(exp_deg_Percentage,exp_deg_Days,modelConfig.timeStep);
modelConfig.decay.exp_deg.byComponent = thresholds;
%------------------------------ Plotting ---------------------------------%
% true | false   Set true for visualizing the results as the model runs
modelConfig.visualize        = true;
%3D | 2D | coastline --- Visualization Type-------------------------------%
modelConfig.vistype          = 'coastline';
% true | false   Set true for saving the generated images
modelConfig.saveImages       = true;
% Create the colors of the oil
%modelConfig.colorByComponent = colorGradient([1 1 1],[0 0 .7],modelConfig.totComponents)
modelConfig.colorByComponent = [...
    [79h/255, 170/255, 126/255];
    [163/255, 97/255, 199/255];
    [113/255, 177/255, 63/255];
    [197/255, 93/255, 147/255];
    [154/255, 144/255, 65/255];
    [101/255, 136/255, 205/255];
    [208/255, 129/255, 61/255];
    [202/255, 83/255, 82/255];
    ];
modelConfig.colorByDepth     = [...
    [1]];
%-------------------- Initial particle vector size -----------------------%
%----------------- This is just for memory allocation --------------------%
if modelConfig.decay.exp_degradation
    % Days in which 99% of the longest-lived oil is degraded
    max_days = -log(.01)/min(dailyDecayRates);
else
    %
    max_days = length(datenum(modelConfig.startDate):datenum(modelConfig.endDate));
end
largestPossibleArray = max_days*(24/modelConfig.timeStep);
modelConfig.initPartSize = ceil(largestPossibleArray/(modelConfig.totComponents*2));
%-------------------------- Call core routine ----------------------------%
OilSpillModel(modelConfig);
toc()
