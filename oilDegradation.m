function Particles = oilDegradation(Particles, modelConfig, spillData)
      % Verify that we need to degrade something
      if modelConfig.decay.evaporate == 1 || modelConfig.decay.biodeg == 1 ||...
          modelConfig.decay.burned == 1 || modelConfig.decay.collected == 1
        parts_evaporated = 0;
        parts_burned     = 0;
        parts_collected  = 0;
        burning_radius = 3;

        % Cicle particle per particle
        random_particles = randperm(length(Particles));
        for particle = random_particles
          if Particles(particle).isAlive == 1;
            % Get the particle component
            component_p = Particles(particle).component;
            % If burned is activated, calculate the distance from source
            if modelConfig.decay.burned == 1
              ind = Particles(particle).currTimeStep;
              lat_p = Particles(particle).lats(ind);
              lon_p = Particles(particle).lons(ind);
              % Haversine formula
              delta_lat = deg2rad(lat_p - modelConfig.lat);
              delta_lon = deg2rad(lon_p - modelConfig.lon);
              a = sin(delta_lat/2)^2 + cos(deg2rad(modelConfig.lat)) *...
                  cos(deg2rad(lat_p)) * sin(delta_lon/2)^2;
              c = 2 * atan2(sqrt(a),sqrt(1-a));
              distanceFromSource = 6371 * c;
            end
            % Evaporated
            if modelConfig.decay.evaporate == 1 && parts_evaporated < spillData.ts_evaporated &&...
                ismember(component_p,1:4)
              Particles(particle).isAlive = 0;
              Particles(particle).status  = 'E';
              parts_evaporated = parts_evaporated + 1;
            % Burned
            elseif modelConfig.decay.burned == 1 && parts_burned < spillData.ts_burned &&...
                distanceFromSource <= burning_radius
              Particles(particle).isAlive = 0;
              Particles(particle).status  = 'B';
              parts_burned = parts_burned + 1;
            % Collected
            elseif modelConfig.decay.collected == 1 && parts_collected <  spillData.ts_recovered
              Particles(particle).isAlive = 0;
              Particles(particle).status  = 'C';
              parts_collected = parts_collected + 1;
            % Degradated
            elseif modelConfig.decay.biodeg == 1
              if rand > modelConfig.decay.byComponent(component_p)
                Particles(particle).isAlive = 0;
                Particles(particle).status  = 'D';
              end
            else
              break
            end
          end
        end
      end % End Oil Decay
