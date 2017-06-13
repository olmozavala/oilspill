classdef Particle < handle
   properties
      dates % date[] Indicates the dates for which the particle has been alive in the model
      lats % float[] Latitutes for each time step
      lons % float[] Longitued for each time step
      depths % float[] Depths for each time step
      lifeTime % int The time in minutes that the particle has been alive
      component % int The component of the particle 
      currTimeStep  % int The current time step the particle is. It start at 1 and increases by one for each delta t
      isAlive % Bool Indicates if the particle is still alive
      status % String A String that indicates the status of the particle. Each model should define it
      lastDepth % Float that indicates the last depth of the particle
      lastDepthIdx % Integer that indicates the last depth (its index) of the particle
      lastLat % Float that indicates the last lat of the particle
      lastLon % Float that indicates the last lat of the particle
      pele %element of particle
   end
	methods
	   function obj = Particle(startDate, initSize,  diffusionLat, diffusionLon, component, lat, lon, depth, depthIdx)
            obj.dates = nan(initSize,1);
            obj.lats = nan(initSize,1);
            obj.lons = nan(initSize,1);
            obj.depths = nan(initSize,1);
            obj.dates(1) = startDate;
            obj.lifeTime = 0;
            obj.currTimeStep = 1;
            obj.isAlive = 1;
            obj.status = 'M';
            obj.component = component;
            % Makes it a litle more efficient
            t1 = lat+randn*diffusionLat;
            t2 = lon+randn*diffusionLon;
            obj.lats(1) = t1;
            obj.lons(1) = t2;
            obj.depths(1) = depth;
            obj.lastDepth = depth;
            obj.lastDepthIdx = depthIdx;
            obj.lastLat = t1;
            obj.lastLon=  t2;
	    obj.pele = 0;
	   end
	end
end
      % For the oilspill we use (in the status of the particle): 
      %         'M' Moving and alive
      %         'L' In land
      %         'B' Burned
      %         'E' Evaporated
      %         'R' Recovered

