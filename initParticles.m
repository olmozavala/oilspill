function particles = initParticles(particles, spillData, modelConfig, currDay, currHour)
    idxPart = length(particles)
    
    % Add particles at surface
    for part = [0:spillData.ts_particles]
        % Add particle at surface
        startDate = datenum(modelConfig.startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;
        particles(idxPart) = Particle(currDay, modelConfig.initPartSize, 1, modelConfig.lat, modelConfig.lon)
        idxPart = idxPart + 1
    end
