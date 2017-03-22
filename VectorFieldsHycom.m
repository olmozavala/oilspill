classdef VectorVieldsHycom
   properties
      U % U variable for current time
      V % V variable for current time
      UT2 % U variable for next time
      VT2 % V variable for next time
      UW % U (wind) variable for current time
      VW % V (wind) variable for current time
      UWT2 % U (wind) variable for next time
      VWT2 % V (wind) variable for next time
      currHour % Current hour of the model
      currDay % Current day of the model
      LAT % Latitude meshgrid of the currents
      LON % Longitude meshgrid of the currents
	atmFilePrefix % File prefix for the atmospheric netcdf files
	oceanFilePrefix  % File prefix for the ocean netcdf files
      uvar
      vvar end
	methods
	   function obj = VectorVieldsHycom(currHour, atmFilePrefix, oceanFilePrefix, uvar, vvar)
			obj.currHour = currHour;
			obj.currDay = -1;
                  obj.atmFilePrefix = atmFilePrefix;
                  obj.oceanFilePrefix = oceanFilePrefix;
                  obj.uvar = uvar;
                  obj.vvar = vvar;
	   end
         function obj = readUV(obj, modelHour, modelDay)

            eps = .01; % Modified epsilon to make it work with ceil
            fixedWindDeltaT = 6; % This is the delta T for the wind fields

            windFileNum = floor(modelHour/fixedWindDeltaT)+1;
            windFileT2Num = ceil( (modelHour + eps)/fixedWindDeltaT)+1;

            % These variables indicate if we have to read new files   
            readWind = false;
            readWindT2 = false;
            readOcean = false;
            readOceanT2 = false;
            readNextDayWind = false;

            idx_depth_1  = 10;

            % Create the file names 
            readOceanFile = [obj.oceanFilePrefix,sprintf('%03d',modelDay),'_00_3z.nc'];
            readOceanFileT2 = [obj.oceanFilePrefix,sprintf('%03d',modelDay+1),'_00_3z.nc'];
            readWindFile = [obj.atmFilePrefix,num2str(modelDay),'_',num2str(windFileNum),'.nc'];
            
            % Verify the first time we get data
            if modelHour == 0 && obj.currDay == -1
                % On the first day we read wind and currents
                readWind = true;
                readWindT2 = true;
                readOcean = true;
                readOceanT2 = true;

                % Read Lat and Lon from files and create meshgrids for currents and wind
                lat = double(ncread(readOceanFile,'Latitude'));
                lon = double(ncread(readOceanFile,'Longitude'));
                [obj.LON, obj.LAT] = meshgrid(lon,lat);
            else
                % Verify we haven't increase the file name
                if floor(modelHour/fixedWindDeltaT)~= floor(obj.currHour/fixedWindDeltaT)
                    readWindT2 = true;
                end

                % Verify the next time step for the wind is still in this day
                if windFileT2Num > (24/fixedWindDeltaT) &&  (mod(modelHour,fixedWindDeltaT) == 0 )
                    readNextDayWind = true;
                    readWindT2 = true;
                end

                % Decide if we need to read new data for the currents
                if modelDay ~= obj.currDay
                    readOceanT2 = true;
                    obj.U = obj.UT2;
                    obj.V = obj.VT2;
                end
            end

            % Verify if we need to read the winds for the next day or the current day
            if readNextDayWind
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay+1),'_1.nc'];
                obj.UW = obj.UWT2;
                obj.VW = obj.VWT2;
            else
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay),'_',num2str(windFileT2Num),'.nc'];
            end

            % Verify if we need to read the winds for the current day
            if readWind
                %readWindFile
                obj.UW = double(ncread(readWindFile,'U_Viento'));
                obj.VW = double(ncread(readWindFile,'V_Viento'));
            end
            % Verify if we need to read the winds for the next day
            if readWindT2
                %readWindFileT2
                obj.UWT2 = double(ncread(readWindFileT2,'U_Viento'));
                obj.VWT2 = double(ncread(readWindFileT2,'U_Viento'));
            end
            % Verify if we need to read the currents of the current day
            if readOcean
                %readOceanFile
                obj.U = double(ncread(readOceanFile,obj.uvar,[1, 1, idx_depth_1, 1],[Inf, Inf, 1, 1])');
                obj.V = double(ncread(readOceanFile,obj.vvar,[1, 1, idx_depth_1, 1],[Inf, Inf, 1, 1])');
            end
            % Verify if we need to read the currents of the next day
            if readOceanT2
                %readOceanFileT2
                obj.UT2 = double(ncread(readOceanFileT2,obj.uvar,[1, 1, idx_depth_1, 1],[Inf, Inf, 1, 1])');
                obj.VT2 = double(ncread(readOceanFileT2,obj.vvar,[1, 1, idx_depth_1, 1],[Inf, Inf, 1, 1])');
            end

            obj.currDay = modelDay;
            obj.currHour = modelHour;
         end
	end
  end

