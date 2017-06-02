% In this new version, the objective is to make the code as efficient as possible
close all; clear; clc; format compact

tic()
[inputFolder outputFolder] = addLocalPaths();


modelConfig                    = ModelConfig; % Create an object of type ModelConfig
modelConfig.lat                =  28.738;
modelConfig.lon                = -88.366;
modelConfig.startDate          = datetime(2010,04,22); % Year, month, day
modelConfig.endDate            = datetime(2010,08,24); % Year, month, day
modelConfig.timeStep           = 6;    % 6 Hours time step
modelConfig.barrelsPerParticle = 10; % How many barrels of oil are we goin to simulate one particle.
%modelConfig.depths             = [0 3 350 700 1100]; % First index MUST be 0 (surface)
modelConfig.depths             = [0,100,1000]; % First index MUST be 0 (surface)
modelConfig.depths             = [0]; % First index MUST be 0 (surface)

modelConfig.components         = [[.1 .1 .1 .1 .1 .1 .1 .3]; ...
                                  [0 0 0 .1 .1 .1 .2 .5]; ...
                                  [0 0 0 0 .1 .1 .2 .6]; ...
                                  [0 0 0 0 .1 .1 .2 .6]; ...
                                  [0 0 0 0 0 .1 .2 .7]];

modelConfig.totComponents      = length(modelConfig.components(1,:)); 

modelConfig.visualize          = false; % Indicates if we want to visualize the results as the model runs.
modelConfig.saveImages         = false; % Indicate if we want to save the generated images
%modelConfig.colorByComponent   = colorGradient([1 1 1],[0 0 .7],modelConfig.totComponents)% Creates the colors of the oil
modelConfig.colorByComponent   = [ [1 0 0]; [.89 .69 .17]; [1 1 0]; [0 0 1]; [0 1 0]; [0 1 1]; [0 0 1]; [1 0 1];[.7 0 .7]];
modelConfig.colorByDepth       = [ [0 0 1]; [1 0 0]; [1 1 0]; [0 1 0]; [0 1 1]];
modelConfig.outputFolder       = outputFolder;


modelConfig.windcontrib        = 0.035;   % Wind contribution
modelConfig.turbulentDiff      = [1,1,1,1,1]; % Turbulent diffusion (surface and each depth)
modelConfig.diffusion          = [.05,.05,.05,.05,.05];% (2 STD)(in km) for random diffusion when initializing particles

%modelConfig.subSurfaceFraction = [1/5,1/5,1/5,1/5,1/5];
modelConfig.subSurfaceFraction = [1/2,1/2];
modelConfig.decay.evaporate    = 1;
modelConfig.decay.exp_degradation = 1; % Exponential degradation
modelConfig.decay.burned       = 1;
modelConfig.decay.burned_radius = 3; % Radius where we are going tu burn particles (in km)
modelConfig.decay.collected    = 1;

% TODO validate the sizes of turbulentDiff, diffusion and subSurfaceFraction with number of subsurface

modelConfig.decay.exp_deg.byComponent  = threshold(95,[15, 30, 45, 60, 75, 90,120, 180],modelConfig.timeStep);
% This is just for memory allacation  (TODO make something smarter)
modelConfig.initPartSize = 10*(24/modelConfig.timeStep); % Initial size of particles vector array of lats, lons, etc.

OilSpillModel(modelConfig);
toc()
