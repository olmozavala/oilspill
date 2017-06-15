classdef SpillByTimeStep
   properties
        decay.evaporate % Indicates how many particles should be evaporated in each time step
        decay.biodeg    % Indicates how many particles should be biodegraded in each time step
        decay.burned    % Indicates how many particles should be burned in each time step
        decay.collected % Indicates how many particles should be collected in each time step
        particles.init % array indicating how many particles should be initialized in each time step for every depth
   end
    methods

    end
end
