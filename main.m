sudp apt% In this new version, the objective is to make the code as efficient as possible
close all; clear; clc; format compact

atmInputFolder   = '/home/julio/Desktop/Oil_spill_simulator_v1/campos_de_velocidad/WRF_2010/';
oceanInputFolder = '/home/julio/Desktop/Oil_spill_simulator_v1/campos_de_velocidad/HYCOM_2010_31p0/';
output_dir       = '/home/julio/Desktop/Oil_spill_v3/resultados/';
addLocalPaths(atmInputFolder,oceanInputFolder,output_dir)

turb_dif = 1;
wind_factor = 0.035 ;

modelConfig                    = SpillInfo;
modelConfig.lat                =  28.738;
modelConfig.lon                = -88.366;
modelConfig.startDate          = datetime(2010,04,22); % Year, month, day
modelConfig.endDate            = datetime(2010,07,30); % Year, month, day
modelConfig.timeStep           = 2;    % 6 Hours time step
modelConfig.barrelsPerParticle = 1000; % How many barrels of oil are we goin to simulate one particle.
modelConfig.depths             = [0 3 1100];
modelConfig.components         = [[0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05];...
                                  [0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05];...
                                  [0.05 0.05 0.05 0.05 0.10 0.20 0.20 0.30]];
modelConfig.subSurfaceFraction = [1/2,1/2];
modelConfig.decay.evaporate    = 1;
modelConfig.decay.biodeg       = 1;
modelConfig.decay.burned       = 1;
modelConfig.decay.collected    = 1;
modelConfig.decay.byComponent  = threshold(95,[4, 8, 12, 16, 20, 24, 28, 32],modelConfig.timeStep);
modelConfig.initPartSize = 10*(24/modelConfig.timeStep); % Initial size of particles vector array of lats, lons, etc.

% La funcion cantidades_por_dia determina las distintas cantidades de petroleo
% a partir de los datos del derrame en el archivo "datos_derrame.csv"
% FechasDerrame      = Dias julianos en los que hubo derrame de petroleo
% SurfaceOil1        = Cantidad de petroleo en superficie
% VBU                = Cantidad de petroleo quemado
% VE                 = Cantidad de petroleo evaporado
% VNW                = Cantidad de petroleo recuperado en agua
% VDB                = Cantidad de petroleo dispersado en la sub-superficie
[FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB] = cantidades_por_dia;
spillData          = OilSpillData(FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB);
VF                 = VectorFields(0);
advectingParticles = false;          % Indicate when should we start reading the UV fields
Particles          = Particle.empty; % Start the array of particles empty

for currDay = datevec2doy(datevec(modelConfig.startDate)):datevec2doy(datevec(modelConfig.endDate))
  % Verify we have some data in this day
  if any(FechasDerrame == currDay)
    advectingParticles = true; % We should start to reading vector fields and advecting particles
    % Read from Fechas derrame and init proper number of particles. In a function
    spillData = spillData.splitByTimeStep(modelConfig, currDay);
  end
  tic
  for currHour = 0:modelConfig.timeStep:24-modelConfig.timeStep
    %sprintf('---- Hour %d -----',currHour)
    % Computes the current date from the currentHour and currentDay
    currDate = datenum(modelConfig.startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;
    if advectingParticles
      % Add the proper number of particles for this time step
      Particles = initParticles(Particles, spillData, modelConfig, currDay, currHour);
      %sprintf('---- hour %d -----',currHour)
      VF        = VF.readUV(modelConfig.timeStep, currHour, currDay);
      % Advect particles
      Particles = advectParticles(VF, modelConfig, Particles, currDate, turb_dif);
      % Oil decay
      if modelConfig.decay.evaporate == 1 || modelConfig.decay.biodeg == 1 ||...
          modelConfig.decay.burned == 1 || modelConfig.decay.collected == 1
        parts_evaporated = 0;
        parts_burned     = 0;
        parts_collected  = 0;
        % Cicle particle per particle
        random_particles = randperm(length(Particles));
        for particle = random_particles
          if Particles(particle).isAlive == 1;
            % Get the particle component
            component_p = Particles(particle).component;
            % If burned is activated, calculate the distance from source
            if modelConfig.decay.burned == 1
              ind = find(Particles(particle).lats ~= 0,1,'last');
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
            if modelConfig.decay.evaporate == 1 && parts_evaporated < parts_to_evaporate &&...
                ismember(component_p,1:4)
              Particles(particle).isAlive = 0;
              Particles(particle).status  = 'E';
              parts_evaporated = parts_evaporated + 1;
            % Burned
            elseif modelConfig.decay.burned == 1 && parts_burned < parts_to_burn &&...
                distanceFromSource <= burning_radius
              Particles(particle).isAlive = 0;
              Particles(particle).status  = 'B';
              parts_burned = parts_burned + 1;
            % Collected
            elseif modelConfig.decay.collected == 1 && parts_collected < parts_to_collect
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
    end
  end
  toc
  sprintf('---- Day %d -----',currDay)
end