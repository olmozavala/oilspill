function plotParticlesSingleTime(Particles, modelConfig, f)
    hold on;
    %% Animating particles using streamline

    liveParticles = findobj(Particles, 'isAlive',true);

    % Get all the particles components for the live ones
    particleComponents =  [liveParticles.component];
    % Iterate over all the components
    for component = 1:modelConfig.totComponents
        currParticles = particleComponents == component;
        scatter3([Particles(currParticles).lastLon], [Particles(currParticles).lastLat], ...
                    -[Particles(currParticles).lastDepth],9,modelConfig.colorByComponent(component,:),'filled');
        scatter3([Particles(currParticles).lastLon], [Particles(currParticles).lastLat], ...
                    -[Particles(currParticles).lastDepth],9,modelConfig.colorByComponent(component,:),'filled');
    end

    % Dead particles drawn in red color
    deadParticles = findobj(Particles, 'isAlive',false);
    scatter3([deadParticles.lastLon], [deadParticles.lastLat], ...
                -[deadParticles.lastDepth],9,'r','filled');
    drawnow

    %totPart = length(Particles);
    %ParticlesCell = {};
    %pIdx = 1;
%    for ii =  1:totPart'% Iterate over the particles
%        pos = [Particles(ii).lastLon, Particles(ii).lastLat, -Particles(ii).lastDepth];
%        ParticlesCell{ii} = pos;
%    end
%    streamparticles(ParticlesCell,length(ParticlesCell), 'Animate',0)
%    drawnow
