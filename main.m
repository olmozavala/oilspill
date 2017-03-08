% In this new version, the objective is to make the code as efficient as possible
close all; clear; clc; format compact

addLocalPaths()

modelConfig = SpillInfo;

modelConfig.startDate = datetime(2010,05,01);
modelConfig.endDate =  datetime(2010,12,02);
modelConfig.lat= 28;
modelConfig.lon = -88;%258
modelConfig.depths = [0 300 1000]; 
modelConfig.components = [[0.1 0.1 0.1 0.1 0.1 0.1 0.1 0.3]; ...
                          [0.0 0.0 0.0 0.1 0.1 0.1 0.2 0.5]; ...
                          [0.0 0.0 0.0 0.0 0.0 0.1 0.2 0.7]];

modelConfig.subSurfaceFraction = [1/3,2/3];
modelConfig.timeStep = 2; % 6 Hours time step
modelConfig.initPartSize = 10*(24/modelConfig.timeStep); % Initial size of particles vector array of lats, lons, etc.
modelConfig.decay.evaporate = 1;
modelConfig.decay.biodeg = 1;
modelConfig.decay.burned = 1;
modelConfig.decay.collected = 1;

modelConfig.decay.byComponent = [umbral(15), umbral(30), umbral(45), umbral(60), umbral(75),...
                                            umbral(90), umbral(120), umbral(180)];

%% La funcion cantidades_por_dia determina las distintas cantidades de petroleo
% a partir de los datos del derrame en el archivo "datos_derrame.csv"
% FechasDerrame      = Dias julianos en los que hubo derrame de petroleo
% SurfaceOil1        = Cantidad de petroleo en superficie
% VBU                = Cantidad de petroleo quemado
% VE                 = Cantidad de petroleo evaporado
% VNW                = Cantidad de petroleo recuperado en agua
% VDB                = Cantidad de petroleo dispersado en la sub-superficie
[FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB] = cantidades_por_dia;

spillData = OilSpillData(FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB);

VF = VectorFields(0);

advectingParticles = false; % Indicate when should we start reading the UV fields
Particles = Particle.empty; % Start the array of particles empty

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
            VF = VF.readUV( modelConfig.timeStep, currHour, currDay);
            % Advect particles

            Particles = advectParticles(VF, modelConfig, Particles, currDate);
            % Example for finding specific particles
        end
    end
    toc
    sprintf('---- Day %d -----',currDay)
end
