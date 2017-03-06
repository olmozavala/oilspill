classdef DataHelper
   properties
      	SpillInfo  % Object with a reference to the object that contains information about the spill
	  	currDate	% Current date in the iteration of the oilspill
		atmInputFolder  % Input folder where de atm data is stored
		oceanInputFolder  % Input folder where de oceanic data is stored
		atmFilePrefix	 % File prefix for the atmospheric netcdf files
		oceanFilePrefix  % File prefix for the ocean netcdf files
		oceanTimeStep    % Time step of the oceanic files in hours. Do we have files every day, every hour?
		atmTimeStep       % Time step of the atmosfpheric files in hours. Do we have files every day, every hour?
		Uatm   % Computed U value for the current time step
		Vatm   % Computed V value for the current time step
		UP1atm   % Computed U value for the next time step
		VP1atm   % Computed V value for the next time step
   end
	methods
	   function obj = DataHelper()
			currDate = -1; % Init the 
	   end
	   function obj = readaData(currDate)

	   end
	end
end

