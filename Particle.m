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
   end
	methods
	   function obj = Particle(startDate, initSize, component, lat, lon, depth)
            obj.dates = cell(initSize);
            obj.lats = zeros(initSize);
            obj.lons = zeros(initSize);
            obj.depths = zeros(initSize);
            obj.dates{1} = startDate;
            obj.lifeTime = 0;
            obj.currTimeStep = 1;
            obj.isAlive = true;
            obj.status = 'M';
            obj.component = component;
            obj.lats(1) = lat;
            obj.lons(1) = lon;
            obj.depths(1) = depth;
	   end
	end
end
      % For the oilspill we use: 
      %         'M' Moving and alive
      %         'L' In land
      %         'B' Burned
      %         'E' Evaporated
      %         'R' Recovered

