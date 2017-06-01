function Particles = advectParticles(VF, modelConfig, Particles, nextTime)
    DeltaT = modelConfig.timeStepSec; % Move DT to seconds
    R = modelConfig.R;                % Mean radious of the earth

    % Get live particles 
    LiveParticles = findobj(Particles, 'isAlive',true);
    sprintf('---- Live Particles %d -----',length(LiveParticles))

    numParticles = length(LiveParticles);
    % Get particles depth
    allDepths= [LiveParticles.lastDepth];
    % All lats and lons
    allLat = [LiveParticles.lastLat];
    allLon = [LiveParticles.lastLon];

    U = VF.U;
    V = VF.V;

    UT2 = VF.UT2;
    VT2 = VF.VT2;

    % Incorporate the force of the wind (using the rotated winds to the surface)
    U(:,:,1) = VF.U(:,:,1) + VF.UWR*modelConfig.windcontrib;
    V(:,:,1) = VF.V(:,:,1) + VF.VWR*modelConfig.windcontrib;
    
    UT2(:,:,1) = UT2(:,:,1) + VF.UWRT2*modelConfig.windcontrib;
    VT2(:,:,1) = VT2(:,:,1) + VF.VWRT2*modelConfig.windcontrib;

    Upart = interp3(VF.LON(1,:), VF.LAT(:,1), VF.depths(unique(VF.depthsRelativeIndx)), VF.U, allLon, allLat, allDepths);
    Vpart = interp3(VF.LON(1,:), VF.LAT(:,1), VF.depths(unique(VF.depthsRelativeIndx)), VF.U, allLon, allLat, allDepths);

    % Move particles to dt/2 (Runge Kutta 2)
    k1lat = (DeltaT*Vpart)*(180/(R*pi));
    k1lon = ((DeltaT*Upart)*(180/(R*pi))).*cosd(allLat);

    % Make half the jump 
    tempK2lat = allLat + k1lat/2;
    tempK2Lon = allLon + k1lon/2;

    % Interpolate U and V to DeltaT/2 
    Uhalf = U + (UT2 - U)/2;
    Vhalf = V + (VT2 - V)/2;

    % Interpolate U and V to New particles positions using U at dt/2
    UhalfPart = interp3(VF.LON(1,:), VF.LAT(:,1), VF.depths(unique(VF.depthsRelativeIndx)), Uhalf, tempK2Lon, tempK2lat, allDepths);
    VhalfPart = interp3(VF.LON(1,:), VF.LAT(:,1), VF.depths(unique(VF.depthsRelativeIndx)), Vhalf, tempK2Lon, tempK2lat, allDepths);

    % Add turbulent-diffusion
    Uturb = UhalfPart .* (-modelConfig.turbulentDiff + (2*modelConfig.turbulentDiff) .* rand(size(UhalfPart)));
    Vturb = VhalfPart .* (-modelConfig.turbulentDiff + (2*modelConfig.turbulentDiff) .* rand(size(VhalfPart)));

    UhalfPart = UhalfPart + Uturb;
    VhalfPart = VhalfPart + Vturb;

    % Move particles to dt
    newLatP= allLat + (DeltaT*VhalfPart)*(180/(R*pi));
    newLonP= allLon + ((DeltaT*UhalfPart)*(180/(R*pi))).*cosd(allLat);

    % Iterate over the particles and add the new positions
    for idxPart = 1:numParticles
        % Get current particle
        particle = LiveParticles(idxPart);
        % Add in one the current time step of the particle
        particle.currTimeStep = particle.currTimeStep + 1;
        particle.lats(particle.currTimeStep) = newLatP(idxPart);
        particle.lons(particle.currTimeStep) = newLonP(idxPart);
        %particle.depths(particle.currTimeStep) = particle.lastDepth;
        %particle.lastDepth = particle.lastDepth;% If someday we would like to change the depth

        particle.lastLat = newLatP(idxPart);
        particle.lastLon = newLonP(idxPart);

        % Update the next time
        particle.dates(particle.currTimeStep) = nextTime;
        % Lifetime of the particle in hours
        particle.lifeTime = particle.lifeTime + modelConfig.timeStep;
    end
end
