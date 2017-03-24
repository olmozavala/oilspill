function Particles = advectParticles(VF, modelConfig, Particles, currDate, turb_dif)
    DeltaT = modelConfig.timeStep*3600; % Move DT to seconds
    R=6371e+03;                 % Radio medio de la tierra (Gill)

    % Get live particles 
    LiveParticles = findobj(Particles, 'isAlive',true);

    % Iterate over the different depths
    dIndx= 1; % Current depth index
    for depth = modelConfig.depths
        % Get particles depth
        SameDepthParticles = findobj(LiveParticles, 'depths',depth);
        numParticles = length(SameDepthParticles);

        % Reading all the positions for particles with the same depth
        latP = zeros(numParticles);
        lonP = zeros(numParticles);

        % Get current particle
        latP = [SameDepthParticles.lats];
        lonP = [SameDepthParticles.lons];

        % Get the depth indices for the current particles
        currDepthIndx = VF.depthsIndx(dIndx,:);
        if currDepthIndx(1) == currDepthIndx(2)
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

        % Interpolate U and V to DeltaT/2 
        Uhalf = U + (UT2 - U)/2;
        Vhalf = V + (VT2 - V)/2;
        % Interpolate the U and V fields for the particles positions
        Upart = interp2(VF.LON, VF.LAT, U, lonP, latP);
        Vpart = interp2(VF.LON, VF.LAT, V, lonP, latP);
        % Move particles to dt/2 (Runge Kutta 2)
        k1lat = (DeltaT*Vpart)*(180/(R*pi));
        k1lon = ((DeltaT*Upart)*(180/(R*pi))).*cosd(latP);
        % Make half the jump 
        tempK2lat = latP + k1lat/2;
        tempK2Lon = lonP + k1lon/2;
        % Interpolate U and V to New particles positions using U at dt/2
        UhalfPart = interp2(VF.LON, VF.LAT, Uhalf, tempK2Lon, tempK2lat);
        VhalfPart = interp2(VF.LON, VF.LAT, Vhalf, tempK2Lon, tempK2lat);
        % Add turbulent-diffusion
        Uturb = UhalfPart .* (-turb_dif + (2*turb_dif) .* rand(size(UhalfPart)));
        Vturb = VhalfPart .* (-turb_dif + (2*turb_dif) .* rand(size(VhalfPart)));
        UhalfPart = UhalfPart + Uturb;
        VhalfPart = VhalfPart + Vturb;
        % Move particles to dt
        newLatP= latP + (DeltaT*VhalfPart)*(180/(R*pi));
        newLonP= lonP + ((DeltaT*UhalfPart)*(180/(R*pi))).*cosd(latP);
        % Iterate over the particles and add the new positions
        for idxPart = 1:length(SameDepthParticles)
            % Get current particle
            particle = SameDepthParticles(idxPart);
            % Add in one the current time step of the particle
            particle.currTimeStep = particle.currTimeStep + 1;
            particle.lats(particle.currTimeStep) = newLatP(idxPart);
            particle.lons(particle.currTimeStep) = newLonP(idxPart);
            particle.depths(particle.currTimeStep) = particle.depths(particle.currTimeStep-1);

            % Update the next date
            particle.dates{particle.currTimeStep} = currDate;
            % Lifetime of the particle in hours
            particle.lifeTime = particle.lifeTime + modelConfig.timeStep;
        end
        % Increment the index for the current depth value
        dIndx = dIndx + 1;
    end
