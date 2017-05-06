function Particles = advectParticles(VF, modelConfig, Particles, nextTime)
    DeltaT = modelConfig.timeStep*3600; % Move DT to seconds
    R=6371e+03;                 % Radio medio de la tierra (Gill)

    % Get live particles 
    LiveParticles = findobj(Particles, 'isAlive',true);
    sprintf('---- Live Particles %d -----',length(LiveParticles))

    % Get particles depth
    particleDepths = [LiveParticles.lastDepth];

    % All lats and lons
    allLat = [LiveParticles.lastLat];
    allLon = [LiveParticles.lastLon];

    % Iterate over the different depths
    dIndx= 1; % Current depth index
    for depth = modelConfig.depths

        % Get the index for the particles at this depth
        currPartIndex = particleDepths == depth;
        % Get the corresponding indexes of the lived particles
        originalIndexes = find(currPartIndex);
        numParticles = sum(currPartIndex);

        % Get current particles lats and lons
        latP = allLat(currPartIndex);
        lonP = allLon(currPartIndex);

        % Get the depth indices for the current particles
        currDepthIndx = VF.depthsIndx(dIndx,:);

        % Verify we are in the surface in order to incorporate the wind contribution
        if depth == 0 
            U = VF.U(:,:,currDepthIndx(1))';
            V = VF.V(:,:,currDepthIndx(1))';

            UT2 = VF.UT2(:,:,currDepthIndx(1))';
            VT2 = VF.VT2(:,:,currDepthIndx(1))';

            % Incorporate the force of the wind (using the rotated winds)
            U = U + VF.UWR*modelConfig.windcontrib;
            V = V + VF.VWR*modelConfig.windcontrib;
            
            UT2 = UT2 + VF.UWRT2*modelConfig.windcontrib;
            VT2 = VT2 + VF.VWRT2*modelConfig.windcontrib;
        else
            % If we are not in the surface, we need to verify if interpolatation for the proper depth is needed
            if currDepthIndx(1) == currDepthIndx(2)
                % In this case the particles are exactly in one depth (no need to interpolate)
                U = VF.U(:,:,currDepthIndx(1))';
                V = VF.V(:,:,currDepthIndx(1))';

                UT2 = VF.UT2(:,:,currDepthIndx(1))';
                VT2 = VF.VT2(:,:,currDepthIndx(1))';
            else
                % In this case we need to interpolate the currents to the proper Depth
                range = VF.depths(currDepthIndx(2)) - VF.depths(currDepthIndx(1));
                distance = depth - VF.depths(currDepthIndx(1));
                toMult = distance/range;
                U = (VF.U(:,:,currDepthIndx(1)) + ...
                        toMult.*(VF.U(:,:,currDepthIndx(2)) - VF.U(:,:,currDepthIndx(1))))';
                V = (VF.V(:,:,currDepthIndx(1)) + ...
                        toMult.*(VF.V(:,:,currDepthIndx(2)) - VF.V(:,:,currDepthIndx(1))))';
                UT2 = (VF.UT2(:,:,currDepthIndx(1)) + ...
                        toMult.*(VF.UT2(:,:,currDepthIndx(2)) - VF.UT2(:,:,currDepthIndx(1))))';
                VT2 = (VF.VT2(:,:,currDepthIndx(1)) + ...
                        toMult.*(VF.VT2(:,:,currDepthIndx(2)) - VF.VT2(:,:,currDepthIndx(1))))';
            end
        end


        % Interpolate the U and V fields for the particles positions
        Upart = interp2(VF.LON, VF.LAT, U, lonP, latP);
        Vpart = interp2(VF.LON, VF.LAT, V, lonP, latP);
        % Move particles to dt/2 (Runge Kutta 2)
        k1lat = (DeltaT*Vpart)*(180/(R*pi));
        k1lon = ((DeltaT*Upart)*(180/(R*pi))).*cosd(latP);
        % Make half the jump 
        tempK2lat = latP + k1lat/2;
        tempK2Lon = lonP + k1lon/2;
        % Interpolate U and V to DeltaT/2 
        Uhalf = U + (UT2 - U)/2;
        Vhalf = V + (VT2 - V)/2;
        % Interpolate U and V to New particles positions using U at dt/2
        UhalfPart = interp2(VF.LON, VF.LAT, Uhalf, tempK2Lon, tempK2lat);
        VhalfPart = interp2(VF.LON, VF.LAT, Vhalf, tempK2Lon, tempK2lat);
        % Add turbulent-diffusion
        Uturb = UhalfPart .* (-modelConfig.turbulentDiff + (2*modelConfig.turbulentDiff) .* rand(size(UhalfPart)));
        Vturb = VhalfPart .* (-modelConfig.turbulentDiff + (2*modelConfig.turbulentDiff) .* rand(size(VhalfPart)));
        UhalfPart = UhalfPart + Uturb;
        VhalfPart = VhalfPart + Vturb;
        % Move particles to dt
        newLatP= latP + (DeltaT*VhalfPart)*(180/(R*pi));
        newLonP= lonP + ((DeltaT*UhalfPart)*(180/(R*pi))).*cosd(latP);

        % Iterate over the particles and add the new positions
        for idxPart = 1:numParticles
            % Get current particle
            particle = LiveParticles(originalIndexes(idxPart));
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
        % Increment the index for the current depth value
        dIndx = dIndx + 1;
    end
