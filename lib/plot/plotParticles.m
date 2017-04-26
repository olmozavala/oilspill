function plotParticles(Particles, startDate, endDate, timeStep)
    DrawGulfOfMexico();
    hold on;
    totPart = length(Particles);

%    %% Animating particlesusing scatter3
%    for currDay = datevec2doy(datevec(startDate)):datevec2doy(datevec(endDate))
%        for currHour = 0:timeStep:24-timeStep
%            currDate = datenum(startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;
%
%            posThisHour = zeros(totPart, 3);
%            % Iterate over all the particles
%            for ii = 1:totPart
%                % Find if they have a position for this date
%                idx = cell2mat(Particles(ii).dates) == currDate;
%                if length(find(idx ~= 0)) > 0
%                    posThisHour(ii,:) = [Particles(ii).lons(idx), Particles(ii).lats(idx), -Particles(ii).depths(idx)];
%                end
%            end
%            idx = posThisHour(:,1) ~= 0;
%            scatter3(posThisHour(idx,1),posThisHour(idx,2),posThisHour(idx,3), 'filled'); 
%            pause(.1);
%        end
%    end
%
 
    %% Animating particles
    view(-10.5,18) % Define the angle of view
    axis tight;
    set(gca,'BoxStyle','full','Box','on')

    %% Animating particles using streamline
    ParticlesCell = {};
    pIdx = 1;
    tic
    % Create array of ones with the size of the particles
    missingParticles = ones(totPart,1);

    for currDay = datevec2doy(datevec(startDate)):datevec2doy(datevec(endDate))
        for currHour = 0:timeStep:24-timeStep
            currDate = datenum(startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;

            posThisHour = zeros(totPart, 3);
            % Iterate over all the particles
            idxMissingParticles = find(missingParticles == 1);
            for ii =  idxMissingParticles'% Iterate over missing particles
                % Find if they have a position for this date
                idx = cell2mat(Particles(ii).dates) == currDate;
                % Verify this particle was active at this time
                if length(find(idx ~= 0)) > 0
                    % append all the positions of the particle from this date. 
                    nonzero = Particles(ii).lons ~= 0;
                    pos = [Particles(ii).lons(nonzero), Particles(ii).lats(nonzero), -Particles(ii).depths(nonzero)];
                    missingParticles(ii) = 0; % Set particle as done!
                    if pIdx == 1
                        ParticlesCell{ii} = pos;
                    else
                        ParticlesCell{ii} = [ParticlesCell{ii};pos];
                    end
                else
                    % In this case the particle wasnt active at that time
                    ParticlesCell{ii} = [Particles(ii).lons(1), Particles(ii).lats(1), -Particles(ii).depths(1)];
                end
            end
        end
        display(currDay)
    end
    toc
    streamparticles(ParticlesCell,length(ParticlesCell), 'Animate',10, 'FrameRate', 10 )









%%%% ------------ THIS IS JUST AN EXAMPLE ----------------------
%
%    ParticlesCell = {};
%    pIdx = 1;
%    for currDay = datevec2doy(datevec(startDate)):datevec2doy(datevec(endDate))
%        for currHour = 0:timeStep:24-timeStep
%            currDate = datenum(startDate.Year-1, 12, 31, currHour, 0, 0) + currDay;
%
%            % Iterate over all the particles
%            for ii = 1:2
%                % Find if they have a position for this date
%                if ii ==  1 & currDay < 114
%                    pos = [Particles(1).lons(1)+rand, Particles(1).lons(1)+rand, 10];
%                    if pIdx > 1
%                        ParticlesCell{ii} = [ParticlesCell{ii};pos];
%                    else
%                        ParticlesCell{ii} = pos;
%                    end
%                end
%                if ii ==  2 
%                    pos = [Particles(1).lons(1)+rand+5, Particles(1).lons(1)+rand+5, 0];
%                    if pIdx > 1
%                        ParticlesCell{ii} = [ParticlesCell{ii};pos];
%                    else
%                        ParticlesCell{ii} = pos;
%                    end
%                end
%            end
%            pIdx = pIdx+1;
%        end
%    end
%
%    streamparticles(ParticlesCell,length(ParticlesCell), 'Animate',10, 'FrameRate', 3 )
