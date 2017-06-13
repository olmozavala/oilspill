function Particles = advectParticlesADCIRC(VF, modelConfig, Particles, nextTime)
%   ADVECTPARTICLESADCIRC     Advect particles one timestep
%   PARTICLES = ADVECTPARTICLESADCIRC(VF, MODELCONFIG, PARTICLES, NEXTIME)
%   takes a VF - VectorFieldsADCIRC object containing a nonstructured mesh
%   node lat/lon coordinates with velocities in each node; a MODELCONFIG
%   object containing the oilspill model time and particle configuration; a
%   PARTICLES object containing number, position and status of particles;
%   and a NEXTTIME value of the next timestep and returns the next position
%   of each particle according to a Runge Kutta advection scheme. 
%
%   This function differs from the 'vanilla' advectParticles function in
%   that it uses nonstructured meshes instead of regular meshes to
%   interpolate the velocities to move the particles. It's current
%   implementation has been tested for the ADCIRC model output. 
%
%   As of now, the function works only for surface velocities, and will not
%   take in account different depths.

%   Changes with respect to vanilla version are marked with ADCIRC
%   EXCLUSIVE.

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
    
    %---------ADCIRC EXCLUSIVE---------------------
    % Get Last Element position of the Particles
    pele = [LiveParticles.pele];
    %==============================================
    
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
            %---------ADCIRC EXCLUSIVE---------------------
            %Use only the surface velocity, as ADCIRC output is 2D.
            U = VF.U;
            V = VF.V;

            UT2 = VF.UT2;
            VT2 = VF.VT2;
            %==============================================
            
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
        
        %---------ADCIRC EXCLUSIVE---------------------
        %Create interpolation object for this depth, this is used with
        %interpTRI1p.
        MeshInterpU = interpTRI1init(VF.LON,VF.LAT,VF.U);
        MeshInterpV = interpTRI1init(VF.LON,VF.LAT,VF.V);
        %==============================================
        
        %---------ADCIRC EXCLUSIVE---------------------
        % Interpolate the U and V fields for the particles positions
        %interpTRI1 uses a non-optimized scatteredinterpolant, interpTRI1p
        %uses the same but optimized, and interpTRI2 uses the Nathan Dill
        %approach to search by element neighbors, but is very slow and
        %buggy.
%         Upart = interpTRI1(VF.LON, VF.LAT, U, lonP, latP)
%         Vpart = interpTRI1(VF.LON, VF.LAT, V, lonP, latP)  
        Upart = interpTRI1p(U, lonP, latP, MeshInterpU);
        Vpart = interpTRI1p(V, lonP, latP, MeshInterpV);
%         Upart = interpTRI2(VF.LON, VF.LAT, VF.ELE, pele, U, lonP, latP)
%         Vpart = interpTRI2(VF.LON, VF.LAT, VF.ELE, pele, V, lonP, latP)  
        %==============================================
        
        % Move particles to dt/2 (Runge Kutta 2)
        k1lat = (DeltaT*Vpart)*(180/(R*pi));
        k1lon = ((DeltaT*Upart)*(180/(R*pi))).*cosd(latP);
        % Make half the jump 
        tempK2lat = latP + k1lat/2;
        tempK2Lon = lonP + k1lon/2;
        % Interpolate U and V to DeltaT/2 
        Uhalf = U + (UT2 - U)/2;
        Vhalf = V + (VT2 - V)/2;
        
        %---------ADCIRC EXCLUSIVE---------------------
        % Interpolate U and V to New particles positions using U at dt/2
        %Same as the interpolation above.
%         UhalfPart = interpTRI1(VF.LON, VF.LAT, Uhalf, tempK2Lon, tempK2lat)
%         VhalfPart = interpTRI1(VF.LON, VF.LAT, Vhalf, tempK2Lon, tempK2lat)  
        UhalfPart = interpTRI1p(Uhalf, tempK2Lon, tempK2lat, MeshInterpU);
        VhalfPart = interpTRI1p(Vhalf, tempK2Lon, tempK2lat, MeshInterpV);
%         UhalfPart = interpTRI2(VF.LON, VF.LAT, VF.ELE, pele, Uhalf, tempK2Lon, tempK2lat)
%         VhalfPart = interpTRI2(VF.LON, VF.LAT, VF.ELE, pele, Vhalf, tempK2Lon, tempK2lat)
        %==============================================
        % Add turbulent-diffusion
        Uturb = UhalfPart .* (-modelConfig.turbulentDiff(dIndx) + (2*modelConfig.turbulentDiff(dIndx)) .* rand(size(UhalfPart)));
        Vturb = VhalfPart .* (-modelConfig.turbulentDiff(dIndx) + (2*modelConfig.turbulentDiff(dIndx)) .* rand(size(VhalfPart)));
        UhalfPart = UhalfPart + Uturb;
        VhalfPart = VhalfPart + Vturb;
        % Move particles to dt
        newLatP= latP + (DeltaT*VhalfPart)*(180/(R*pi));
        newLonP= lonP + ((DeltaT*UhalfPart)*(180/(R*pi))).*cosd(latP);
        
        %---------ADCIRC EXCLUSIVE---------------------
        %The function insideDomain checks if the particles are still inside
        %of the fort.14 defined domain, or have left. If they left then the
        %function returns the old value, if they are still inside the
        %function updates the position value. 
        [yesno,newLonP,newLatP] = insideDomain(lonP,latP, newLonP,newLatP);
        %Check how many particles left. 
        sum(yesno)
        %==============================================
   
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
            
            %---------ADCIRC EXCLUSIVE---------------------
            %This loop checks if the particles have left their previous
            %element when moved, and if they did it searches for the new
            %position.
            if ~(inside(particle.pele,particle.lastLon,particle.lastLat))
                particle.pele = findTRIParticleIni2(newLonP(idxPart),newLatP(idxPart));
%                 if (particle.pele == 0)
%                     particle.isAlive = 0;
%                     particle.status  = 'L';
%                 end
            end
            %==============================================
            
        end
        % Increment the index for the current depth value
        dIndx = dIndx + 1;
    end
