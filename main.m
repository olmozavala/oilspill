% In this new version, the objective is to make the code as efficient as possible
close all; clear; clc; format compact

tic()
addLocalPaths()

modelConfig = SpillInfo;
turb_dif = 1;
wind_factor = 0.035 ;

modelConfig                    = SpillInfo;
modelConfig.lat                =  28.738;
modelConfig.lon                = -88.366;
modelConfig.startDate          = datetime(2010,04,22); % Year, month, day
modelConfig.endDate            = datetime(2010,12,10); % Year, month, day
modelConfig.timeStep           = 6;    % 6 Hours time step
modelConfig.barrelsPerParticle = 10; % How many barrels of oil are we goin to simulate one particle.
modelConfig.depths             = [0 100 1000];
modelConfig.components         = [[0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05],
                                    [0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.0],
                                    [0.05 0.20 0.30 0.20 0.10 0.05 0.05 0.05]];
                                    
modelConfig.totComponents      = 8;
modelConfig.subSurfaceFraction = [1/2,1/2];
modelConfig.decay.evaporate    = 1;
modelConfig.decay.biodeg       = 1;
modelConfig.decay.burned       = 1;
modelConfig.decay.collected    = 1;
modelConfig.decay.byComponent  = threshold(95,[4, 8, 12, 16, 20, 24, 28, 32],modelConfig.timeStep);
modelConfig.initPartSize = 10*(24/modelConfig.timeStep); % Initial size of particles vector array of lats, lons, etc.

atmFilePrefix  = 'Dia_'; % File prefix for the atmospheric netcdf files
oceanFilePrefix  = 'archv.2010_'; % File prefix for the ocean netcdf files
uvar = 'U';
vvar = 'V';

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
VF                 = VectorFields(0, atmFilePrefix, oceanFilePrefix, uvar, vvar);
advectingParticles = false;          % Indicate when should we start reading the UV fields
Particles          = Particle.empty; % Start the array of particles empty

for currDay = datevec2doy(datevec(modelConfig.startDate)):datevec2doy(datevec(modelConfig.endDate))

    % Verify we have some data in this day
    if any(FechasDerrame == currDay)
        advectingParticles = true; % We should start to reading vector fields and advecting particles
        % Read from Fechas derrame and init proper number of particles. In a function
        spillData = spillData.splitByTimeStep(modelConfig, currDay);
    end

    for currHour = 0:modelConfig.timeStep:24-modelConfig.timeStep
	  currDate = datenum(modelConfig.startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;
        if advectingParticles
            % Add the proper number of particles for this time step
            Particles = initParticles(Particles, spillData, modelConfig, currDay, currHour);

            %sprintf('---- hour %d -----',currHour)
            VF = VF.readUV( currHour, currDay, modelConfig);
	    	% Advect particles
		Particles = advectParticles(VF, modelConfig, Particles, currDate, turb_dif);
		% Degrading particles
		Particles = oilDegradation(Particles, modelConfig, spillData);
        end
    end
    sprintf('---- Day %d -----',currDay)
end
toc
%plotParticles(Particles)
