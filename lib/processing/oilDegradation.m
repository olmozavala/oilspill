function Particles = oilDegradation(Particles, modelConfig, spillData)

% Verify that we need to degrade something
if modelConfig.decay.evaporate == 1 || modelConfig.decay.biodeg == 1 ||...
        modelConfig.decay.burned == 1 || modelConfig.decay.collected == 1
     
    % Define the number of particles we need to degradate
    parts_evaporated = 0;
    parts_burned     = 0;
    parts_collected  = 0;
    burning_radius = 3;   

    % Get the live particles
    LiveParticles = findobj(Particles, 'isAlive',true);

    % How many particles we have
    numParticles = length(LiveParticles);

    % Shufle the particles
    random_particles = randperm(numParticles);

    % Degradated
    if modelConfig.decay.biodeg == 1

        % Select all the components for the live particles
        ParticleComponents=  [LiveParticles.component];

        % Choose how many will be biodegradated
        partToKill= rand(1, numParticles) > modelConfig.decay.byComponent(ParticleComponents);

        % Modify the selected particles    
        for finalIndex = random_particles(partToKill)
            LiveParticles(finalIndex).isAlive = 0;
            LiveParticles(finalIndex).status  = 'D';
        end

        % Remove the particles that have been already degraded
        random_particles =  random_particles(~partToKill);
    end

    % For the rest of the live particles, keep degrading
    for partIndx = random_particles
        component_p = LiveParticles(partIndx).component;
        % Evaporated
        if modelConfig.decay.evaporate == 1 && parts_evaporated < spillData.ts_evaporated &&...
                ismember(component_p,1:4)
            LiveParticles(partIndx).isAlive = 0;
            LiveParticles(partIndx).status  = 'E';
            parts_evaporated = parts_evaporated + 1;
            % Burned
        elseif modelConfig.decay.burned == 1 && parts_burned < spillData.ts_burned
            % Calculate the distance from source
            ind = LiveParticles(partIndx).currTimeStep;
            lat_p = LiveParticles(partIndx).lats(ind);
            lon_p = LiveParticles(partIndx).lons(ind);
            % Haversine formula
            delta_lat = deg2rad(lat_p - modelConfig.lat);
            delta_lon = deg2rad(lon_p - modelConfig.lon);
            a = sin(delta_lat/2)^2 + cos(deg2rad(modelConfig.lat)) *...
                cos(deg2rad(lat_p)) * sin(delta_lon/2)^2;
            c = 2 * atan2(sqrt(a),sqrt(1-a));
            distanceFromSource = 6371 * c;
            if distanceFromSource <= burning_radius
                LiveParticles(partIndx).isAlive = 0;
                LiveParticles(partIndx).status  = 'B';
                parts_burned = parts_burned + 1;
            end
            % Collected
        elseif modelConfig.decay.collected == 1 && parts_collected <  spillData.ts_recovered
            LiveParticles(partIndx).isAlive = 0;
            LiveParticles(partIndx).status  = 'C';
            parts_collected = parts_collected + 1;
        else
            % If we get here, then we do not need to degrade any more particles
            break;
        end
    end
end % End Oil Decay