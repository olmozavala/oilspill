function plotParticlesSingleTime(Particles, modelConfig, f, currIter)
    hold on;
    %% Animating particles using streamline

    liveParticles = findobj(Particles, 'isAlive',true);

    % Get all the particles components for the live ones
    particleComponents =  [liveParticles.component];
    % Iterate over all the components
    for component = 1:modelConfig.totComponents
        currParticles = particleComponents == component;
        if currIter == 0
            f = scatter3([Particles(currParticles).lastLon], [Particles(currParticles).lastLat], ...
                        -[Particles(currParticles).lastDepth],9,modelConfig.colorByComponent(component,:),'filled');
            f.XDataSource = '[Particles(currParticles).lastLon]';
            f.YDataSource = '[Particles(currParticles).lastLat]';
            f.ZDataSource = '-[Particles(currParticles).lastDepth]';
        else
            refreshdata
        end
        %scatter3([Particles(currParticles).lastLon], [Particles(currParticles).lastLat], ...
                    %-[Particles(currParticles).lastDepth],9,modelConfig.colorByComponent(component,:),'filled');
    end

    % Dead particles drawn in red color
    deadParticles = findobj(Particles, 'isAlive',false);
    scatter3([deadParticles.lastLon], [deadParticles.lastLat], ...
                -[deadParticles.lastDepth],9,'r','filled');
    drawnow
