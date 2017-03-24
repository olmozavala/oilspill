classdef SpillInfo
   properties
      lat                % Latitude of the spill
      lon                % Longitude of the spill
      startDate          % Start date of the simulation in julian dates
      endDate            % End date of the simulation in julian dates
      timeStep           % The time step is in hours and should be exactly divided by 24
      barrelsPerParticle % How many barrels does a particle represent
      depths             % Array of depths to be used
      components         % Array of components for each depth
      subSurfaceFraction % Array with the fraction of oil spilled at each subsurface depth
      decay
      initPartSize       % How big does we initalize the vector size of particles lats, lons, etc
      totComponents      % Total number of components
   end
   % TODO constructor that initializes all these fields and validates the input
end

