classdef OilSpillData 
   properties
      dates             % Dias julianos en los que hubo derrame de petroleo
      barrels           % Cantidad de petroleo en superficie
      barrelsSub        % Cantidad de petroleo dispersado en la sub-superficie
      burned               % Cantidad de petroleo quemado
      evaporated                % Cantidad de petroleo evaporado
      recovered               % Cantidad de petroleo recuperado en agua
      ts_particles           % Cantidad de petroleo en superficie
      ts_partSub        % Cantidad de petroleo dispersado en la sub-superficie
      ts_burned               % Cantidad de petroleo quemado
      ts_evaporated                % Cantidad de petroleo evaporado
      ts_recovered               % Cantidad de petroleo recuperado en agua
   end
	methods
	   function obj = OilSpillData(FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB)
            obj.dates = FechasDerrame;
            obj.barrels = SurfaceOil;
            obj.barrelsSub = VNW;
            obj.burned = VBU;
            obj.evaporated = VE;
            obj.recovered = VE;
	   end

	   function obj = splitByTimeStep(obj, modelConfig, currDay)

            barrelsPerParticle = modelConfig.barrelsPerParticle;
            
            currDateIdx = find(obj.dates == currDay);

            fractByTimeStep = modelConfig.timeStep/24; % What is the fraction of particles we need to deply by each time step

            obj.ts_particles = ceil(fractByTimeStep*(obj.barrels(currDateIdx)/barrelsPerParticle)); % Total number of particles 
            obj.ts_partSub = ceil(modelConfig.subSurfaceFraction.*fractByTimeStep*(obj.barrelsSub(currDateIdx)/barrelsPerParticle)); % Total number of particles sub surface

            obj.ts_burned = ceil(fractByTimeStep*(obj.burned(currDateIdx)/barrelsPerParticle)); % Number of particles to evaporate
            obj.ts_evaporated = ceil(fractByTimeStep*(obj.evaporated(currDateIdx)/barrelsPerParticle)); % Number of particles to evaporate
            obj.ts_recovered= ceil(fractByTimeStep*(obj.recovered(currDateIdx)/barrelsPerParticle)); % Number of particles recovered

            %fprintf('----------- Part: %0d Burned %0d Eva %0d Rec %0d \n', ...
            %        obj.ts_particles, obj.ts_burned, obj.ts_evaporated, obj.ts_recovered);
            %display(strcat('Part at subsurface: ',num2str(obj.ts_partSub)))
	   end
	end
end
