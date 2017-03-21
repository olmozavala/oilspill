function Particles = advectParticles(VF, modelConfig, Particles, currDate, turb_dif)
DeltaT = modelConfig.timeStep*3600; % Move DT to seconds
R=6371e+03;                 % Radio medio de la tierra (Gill)
% Get live particles 
LiveParticles = findobj(Particles, 'isAlive',true);
numParticles = length(LiveParticles)
% Reading all the positions for live particles
latP = zeros(numParticles);
lonP = zeros(numParticles);
for idxPart = 1:length(LiveParticles)
    % Get current particle
    particle = LiveParticles(idxPart);
    latP(idxPart) = particle.lats(particle.currTimeStep);
    lonP(idxPart) = particle.lons(particle.currTimeStep);
end
% Interpolate VF.U and VF.V to DeltaT/2 
Uhalf = VF.U + (VF.UT2 - VF.U)/2;
Vhalf = VF.V + (VF.VT2 - VF.V)/2;
% Interpolate the U and V fields for the particles positions
Upart = interp2(VF.LON, VF.LAT, VF.U, lonP, latP);
Vpart = interp2(VF.LON, VF.LAT, VF.V, lonP, latP);
% Move particles to dt/2 (Runge Kutta 2)
k1lat = (DeltaT*Vpart)*(180/(R*pi));
k1lon = ((DeltaT*Upart)*(180/(R*pi))).*cosd(latP);
% Make half the jump 
tempK2lat = latP + k1lat/2;
tempK2Lon = lonP + k1lon/2;
% Interpolate VF.U and VF.V to New particles positions using VF.U at dt/2
UhalfPart = interp2(VF.LON, VF.LAT, Uhalf, tempK2Lon, tempK2lat);
VhalfPart = interp2(VF.LON, VF.LAT, Vhalf, tempK2Lon, tempK2lat);
% Add turbulent-diffusion
Uturb = UhalfPart .* (-turb_dif + (2*turb_dif) .* rand(1,length(UhalfPart)));
Vturb = VhalfPart .* (-turb_dif + (2*turb_dif) .* rand(1,length(VhalfPart)));
UhalfPart = UhalfPart + Uturb;
VhalfPart = VhalfPart + Vturb;
% Move particles to dt
newLatP= latP + (DeltaT*VhalfPart)*(180/(R*pi));
newLonP= lonP + ((DeltaT*UhalfPart)*(180/(R*pi))).*cosd(latP);
% Iterate over the particles and add the new positions
for idxPart = 1:length(LiveParticles)
    % Get current particle
    particle = LiveParticles(idxPart);
    % Add in one the current time step of the particle
    particle.currTimeStep = particle.currTimeStep + 1;
    particle.lats(particle.currTimeStep) = newLatP(idxPart);
    particle.lons(particle.currTimeStep) = newLonP(idxPart);
    % Update the next date
    particle.dates{particle.currTimeStep} = currDate;
    % Lifetime of the particle in hours
    particle.lifeTime = particle.lifeTime + modelConfig.timeStep;
end
