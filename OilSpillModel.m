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
    VF                 = VectorFields();
    advectingParticles = false;          % Indicate when should we start reading the UV fields
    Particles          = Particle.empty; % Start the array of particles empty

    %  Initialize the figure for visualization of the particles
    if modelConfig.visualize
        f=figure
        DrawGulfOfMexico();
        %% Animating particles
        view(-10.5,28) % Define the angle of view
        zoom(2)
        axis tight;
        set(gca,'BoxStyle','full','Box','on')
    end

    FinalParticles = {};
    startDay = datevec2doy(datevec(modelConfig.startDate));
    endDay = datevec2doy(datevec(modelConfig.endDate))
    for currDay = startDay:endDay
        sprintf('---- Day %d -----', (currDay - startDay))
        
        % Verify we have some data in this day
        if any(FechasDerrame == currDay)
            advectingParticles = true; % We should start to reading vector fields and advecting particles
            % Read from Fechas derrame and init proper number of particles. In a function
            spillData = spillData.splitByTimeStep(modelConfig, currDay);
        end
        
        if advectingParticles
            for currHour = 0:modelConfig.timeStep:24-modelConfig.timeStep
                currTime = toSerialDate(modelConfig.startDate.Year, currHour, currDay);
                nextTime = toSerialDate(modelConfig.startDate.Year, currHour+modelConfig.timeStep, currDay);
                if advectingParticles
                    % Add the proper number of particles for this time step
                    Particles = initParticles(Particles, spillData, modelConfig, currDay, currHour);

                    % Read winds and currents
                    VF = VF.readUV(currHour, currDay, modelConfig);

                    % Advect particles
                    Particles = advectParticles(VF, modelConfig, Particles, nextTime);
                    
                    % Degrading particles
                    Particles = oilDegradation(Particles, modelConfig, spillData);
                end
                %  Visualize the current step
                if modelConfig.visualize
                    %plotParticlesSingleTime(Particles, modelConfig, f, currDay - startDay)
                    LiveParticles = findobj(Particles, 'isAlive',true);
                    DeadParticles = findobj(Particles, 'isAlive',false);
                    if  currDay - startDay == 0
                        hold on
                        f = scatter3([LiveParticles.lastLon], [LiveParticles.lastLat], ...
                            -[LiveParticles.lastDepth],9,modelConfig.colorByComponent([LiveParticles.component],:),'filled');
                        
                        %h = scatter3([DeadParticles.lastLon], [DeadParticles.lastLat], ...
                        %-[DeadParticles.lastDepth],9,'r','filled');
                        f.XDataMode = 'manual';
                        h.XDataMode = 'manual';
                        drawnow
                    else
                        f.XData = [LiveParticles.lastLon];
                        f.YData = [LiveParticles.lastLat];
                        f.ZData = -[LiveParticles.lastDepth];
                        f.CData = modelConfig.colorByComponent([LiveParticles.component],:);
                        
                        %h.XData = [DeadParticles.lastLon];
                        %h.YData = [DeadParticles.lastLat];
                        %h.ZData = -[DeadParticles.lastDepth];
                        refreshdata
                        drawnow
                    end
                    
                end
                %pause(10)
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

    %% Plotting the results
    %plotParticles(Particles, modelConfig.startDate, modelConfig.endDate, modelConfig.timeStep)
