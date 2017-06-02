function particles = initParticles(particles, spillData, modelConfig, currDay, currHour)
    % INITPARTICLES Initializes the number of particles for each component and depth, at each timestep
    idxPart = length(particles) + 1; % Index of the total number of particles
    totComp = modelConfig.totComponents; % TODO remove hardcoded number 
    
    % Decide how many particles should we deploy at each depth and each component
    particlesByDepth = zeros(size(modelConfig.components)); % This array will contain how many particles should we create for each depth and component

    idxDepth = 1; % Auxiliary index of the current depth
    for depth = modelConfig.depths
        % Surface case
        if depth == 0
            particlesByDepth(idxDepth,:) = modelConfig.components(idxDepth,:) .* spillData.ts_particles;
        else
        % Subsurface case
            particlesByDepth(idxDepth,:) = modelConfig.components(idxDepth,:) .* spillData.ts_partSub(idxDepth-1);
        end
        idxDepth = idxDepth + 1;
    end

    % Which one will be the start date of the particles
    startDate = datenum(modelConfig.startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;

    % Add particles at different depths
    for depthIdx = 1:length(modelConfig.depths)
        % Add particles for different components
        for component = 1:totComp
            % Obtain the fractional number of particles to initialize
            fracParticles = particlesByDepth(depthIdx, component);
            % Compute the number of particles to initialize. Because we have fractional number of particles then
            % we use statistics to decide if we add one more or not
            totParticlesToInit = floor(fracParticles) + ( (fracParticles - floor(fracParticles)) > rand(1) );
            for numPart = 0:totParticlesToInit
                particles(idxPart) = Particle(startDate, modelConfig.initPartSize, modelConfig.diffusionLatDeg(depthIdx), modelConfig.diffusionLonDeg(depthIdx), component, modelConfig.lat, modelConfig.lon, ...
                                            modelConfig.depths(depthIdx), depthIdx);
                idxPart = idxPart + 1;
            end
        end
    end
