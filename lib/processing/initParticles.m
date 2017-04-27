function particles = initParticles(particles, spillData, modelConfig, currDay, currHour)
    idxPart = length(particles) + 1; % Index of the total number of particles
    totComp = 8; % TODO remove hardcoded number 
    
    % Decide how many particles should we deploy at each depth and each component
    idxDepth = 1; % Auxiliary index of the current depth
    particlesByDepth = zeros(size(modelConfig.components)); % This array will contain how many particles should we create for each depth and component

    for depth = modelConfig.depths
        % Surface case
        if depth == 0
            particlesByDepth(idxDepth,:) = ceil(modelConfig.components(idxDepth,:) .* spillData.ts_particles);
        else
        % Subsurface case
            particlesByDepth(idxDepth,:) = ceil(modelConfig.components(idxDepth,:) .* spillData.ts_partSub(idxDepth-1));
        end
        idxDepth = idxDepth + 1;
    end

    % Which one will be the start date of the particles
    startDate = datenum(modelConfig.startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;

    % Add particles at different depths
    for depthIdx = 1:length(modelConfig.depths)
        % Add particles for different components
        for component = 1:totComp
            % Initializes the number of particles decided in the previous step
            for numPart = 0:particlesByDepth(depthIdx, component)
                particles(idxPart) = Particle(startDate, modelConfig.initPartSize, modelConfig.diffusion, component, modelConfig.lat, modelConfig.lon, ...
                                            modelConfig.depths(depthIdx));
                idxPart = idxPart + 1;
            end
        end
    end
