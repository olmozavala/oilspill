function plotParticles(Particles)
    %% Animating particles
    %for currDay = datevec2doy(datevec(modelConfig.startDate)):datevec2doy(datevec(modelConfig.endDate))
    %    for currHour = 0:modelConfig.timeStep:24-modelConfig.timeStep
    %        currDate = datenum(modelConfig.startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;
    %        
    %        % Iterate over all the particles
    %        for ii = 1:length(Particles)
    %
    %            % Find if they have a position for this date
    %            idx = cell2mat(Particles(ii).dates) == currDate;
    %            if length(find(idx ~= 0)) > 0
    %                scatter3(Particles(ii).lats(idx), Particles(ii).lons(idx), ...
    %                                    Particles(ii).depths(idx)); 
    %            end
    %        end
    %        drawnow
    %    end
    %end

    ParticlesCell = {};
    for ii = 1:length(Particles)
        lat = Particles(ii).lats;
        lon = Particles(ii).lons;
        depth = Particles(ii).depths;

        idx = lat~=0;
        pos = [lat(idx), lon(idx), depth(idx)];
        ParticlesCell{ii} = pos;
    end

    view(-10.5,18) % Define the angle of view
    axis tight;
    set(gca,'BoxStyle','full','Box','on')

    streamparticles(ParticlesCell,100,...
            'Animate',10, ... % Number of times to animate the particle positions
            'FrameRate', 3 ...
            );
