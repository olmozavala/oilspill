% In this new version, the objective is to make the code as efficient as possible
close all; clear; clc; format compact

%tic()
addLocalPaths()

modelConfig                    = ModelConfig; % Create an object of type ModelConfig
modelConfig.lat                =  28.738;
modelConfig.lon                = -88.366;
modelConfig.startDate          = datetime(2010,04,22); % Year, month, day
modelConfig.endDate            = datetime(2010,08,26); % Year, month, day
modelConfig.timeStep           = 4;    % 6 Hours time step
modelConfig.R                  = 6371e+03; % Mean radious of the earth
modelConfig.barrelsPerParticle = 50; % How many barrels of oil are we goin to simulate one particle.
modelConfig.depths             = [0 3 1000];

modelConfig.components         = [[0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05]; ...
                                  [0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05]; ...
                                  [0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05]];
modelConfig.totComponents      = length(modelConfig.components(1,:)); 

%modelConfig.colorByComponent   = colorGradient([1 0 0],[0 0 1],modelConfig.totComponents)% Creates the colors of the oil
modelConfig.colorByComponent   = colorGradient([0 1 0],[0 0 1],modelConfig.totComponents)% Creates the colors of the oil


modelConfig.windcontrib        = 0.035;   % Wind contribution
modelConfig.turbulentDiff      = [2,1,.1]; % Turbulent diffusion (surface and each depth)
modelConfig.diffusion          = [.05,.05,.05];% (2 STD)(in km) for random diffusion when initializing particles

modelConfig.subSurfaceFraction = [1/2,1/2];
modelConfig.decay.evaporate    = 1;
modelConfig.decay.exp_degradation = 1; % Exponential degradation
modelConfig.decay.burned       = 1;
modelConfig.decay.burned_radius = 3; % Radius where we are going tu burn particles (in km)
modelConfig.decay.collected    = 1;

modelConfig.decay.exp_deg.byComponent  = threshold(95,[3, 6, 9, 12, 15, 18, 21, 24],modelConfig.timeStep);
% This is just for memory allacation  (TODO make something smarter)
modelConfig.initPartSize = 10*(24/modelConfig.timeStep); % Initial size of particles vector array of lats, lons, etc.

OilSpillModel(modelConfig);
