classdef ModelConfig
   properties
      lat                % Latitude of the spill
      lon                % Longitude of the spill
      startDate          % Start date of the simulation in julian dates
      endDate            % End date of the simulation in julian dates
      timeStep           % The time step is in hours and should be exactly divided by 24
      timeStepSec        % Time step in seconds
      barrelsPerParticle % How many barrels does a particle represent
      depths             % Array of depths to be used
      components         % Array of components for each depth
      subSurfaceFraction % Array with the fraction of oil spilled at each subsurface depth
      decay
      initPartSize       % How big does we initalize the vector size of particles lats, lons, etc
      totComponents      % Total number of components
      colorByComponent   % Colors by each component
      windcontrib        % The percetaje contribution of the windo into the model
      turbulentDiff      % Value of the rubulent diffusion (when advecting particles)
      diffusion          % Variance of the diffusion (in km) when initializing particles 
      diffusionLatDeg    % Variance of the diffusion (in degrees latitude) when initializing particles 
      diffusionLonDeg    % Variance of the diffusion (in degrees longitude) when initializing particles 
      R                  % Mean radious of earth
   end
   % TODO constructor that initializes all these fields and validates the input
   methods
    function obj = set.diffusion(obj, diffVal)
        % Setter function for the variable diffusion. It automatically updates diffusionLatDeg and diffusionLonDeg
        obj.diffusion = diffVal; 
        obj.diffusionLatDeg = km2deg(diffVal./2); % TODO compute diffusion depending on lat and lon
        obj.diffusionLonDeg = km2deg(diffVal./2); % TODO compute diffusion depending on lat and lon
    end
    function obj = set.timeStep(obj, ts)
        % Setter function for the variable time step. Automatically computes time step in seconds
        obj.timeStep    = ts; 
        obj.timeStepSec = ts*3600; % Compute the time step in seconds
    end
   end
end
