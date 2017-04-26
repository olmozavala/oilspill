function plotParticlesSingleTime(Particles)
    hold on;
    %% Animating particles using streamline
    scatter3([Particles.lastLon], [Particles.lastLat], -[Particles.lastDepth],9,'r','filled');
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
