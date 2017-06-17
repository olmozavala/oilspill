% In this new version, the objective is to make the code as efficient as possible
function OilSpillModel(modelConfig)

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
%Check model type
if strcmp(modelConfig.model,'hycom')
    VF  = VectorFields();
elseif strcmp(modelConfig.model,'adcirc')
    %===============ADCIRC EXCLUSIVE==============
    atmFilePrefix  = 'fort.74.'; % File prefix for the atmospheric netcdf files
    oceanFilePrefix  = 'fort.64.'; % File prefix for the ocean netcdf files
    uvar = 'u-vel';
    vvar = 'v-vel';
    global VF
    VF                 = VectorFieldsADCIRC(0, atmFilePrefix, oceanFilePrefix, uvar, vvar);
    VF                 = VF.readLists();
    VF = VF.readUV(0, 115, modelConfig);
end
advectingParticles = false;          % Indicate when should we start reading the UV fields
Particles          = Particle.empty; % Start the array of particles empty

%  Initialize the figure for visualization of the particles
if modelConfig.visualize
    currentVis = VisualizeParticles;
    if strcmp(modelConfig.vistype,'coastline')
        currentVis.drawGulf2d();
    else
        currentVis.drawGulf();
    end
end

FinalParticles = {};
startDay = datevec2doy(datevec(modelConfig.startDate));
endDay = datevec2doy(datevec(modelConfig.endDate));
for currDay = startDay:endDay
  sprintf('---- Day %d -- %d -----', (currDay - startDay), currDay)
  
  % Verify we have some data in this day
  if any(FechasDerrame == currDay)
    advectingParticles = true; % We should start to reading vector fields and advecting particles
    % Read from Fechas derrame and init proper number of particles. In a function
    spillData = spillData.splitByTimeStep(modelConfig, currDay);
  end
    
    if advectingParticles
        for currHour = 0:modelConfig.timeStep:24-modelConfig.timeStep
            currTime = toSerialDate(modelConfig.startDate.Year, currDay, currHour);
            nextTime = toSerialDate(modelConfig.startDate.Year, currDay, currHour+modelConfig.timeStep);
            %       if advectingParticles   % creo que este if sobra
            % Add the proper number of particles for this time step
            Particles = initParticles(Particles, spillData, modelConfig, currDay, currHour);
            
            % Read winds and currents
            VF = VF.readUV(currHour, currDay, modelConfig);
            
            % Advect particles
            if strcmp(modelConfig.model,'hycom')
                Particles = advectParticles(VF, modelConfig, Particles, nextTime);
            elseif strcmp(modelConfig.model,'adcirc')
                Particles = advectParticlesADCIRC(VF, modelConfig, Particles, nextTime);
            end
            
            % Degrading particles
            Particles = oilDegradation(Particles, modelConfig, spillData);
            %       end                     % creo que este if sobra
            %  Visualize the current step
            if modelConfig.visualize
                if strcmp(modelConfig.vistype,'3D')
                    currentVis = currentVis.drawLiveParticles3D(Particles, modelConfig, currTime);
                elseif strcmp(modelConfig.vistype,'2D')
                    currentVis = currentVis.drawLiveParticles2D(Particles, modelConfig, currTime);
                elseif strcmp(modelConfig.vistype,'coastline')
                    currentVis = currentVis.drawParticles2DCoastline(VF,Particles,modelConfig,currTime,currHour,currDay);
                end
            end
        end
  end
  
  % Every 5 days we move away the non active particles.
  if mod(currDay,5) == 0
    NonLiveParticles = findobj(Particles, 'isAlive',false);
    FinalParticles = {FinalParticles,NonLiveParticles};
    Particles = findobj(Particles, 'isAlive',true);
  end
  
  sprintf('---- Tot Particles %d -----',length(Particles))
end
%toc()

% Plotting the results
%plotParticles(Particles, modelConfig.startDate, modelConfig.endDate, modelConfig.timeStep)
