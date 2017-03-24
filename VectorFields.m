classdef VectorFields
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
      depths % Array of depths corresponding to U and V
      depthsMinMax % Array of indexes corresponding to the minumum and maximum depth of the particles
      depthsIndx% Array of indexes corresponding to closest indexes at each depth of the particles
	atmFilePrefix % File prefix for the atmospheric netcdf files
	oceanFilePrefix  % File prefix for the ocean netcdf files
      uvar % Is the name of the variable U inside the netCDF file
      vvar % Is the name of the variable V inside the netCDF file
  end
  methods
	   function obj = VectorFields(currHour, atmFilePrefix, oceanFilePrefix, uvar, vvar)
			obj.currHour = currHour;
			obj.currDay = -1;
                  obj.atmFilePrefix = atmFilePrefix;
                  obj.oceanFilePrefix = oceanFilePrefix;
                  obj.uvar = uvar;
                  obj.vvar = vvar;
	   end
         function obj = readUV(obj, modelHour, modelDay, modelConfig)

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

                % Read Lat,Lon and Depth from files and create meshgrids for currents and wind
                lat = double(ncread(readOceanFile,'Latitude'));
                lon = double(ncread(readOceanFile,'Longitude'));
                obj.depths = double(ncread(readOceanFile,'Depth'));
                
                % Setting the minimum and maximum indexes for the depths of the particles
                % Setting the minimum index
                [val, indx] = min(abs(obj.depths - modelConfig.depths(1)));
                if val == 0
                    obj.depthsMinMax(1) = indx;
                else
                    % Verify we are on the right side of the closest depth
                    if (obj.depths(indx) - modelConfig.depths(1)) < 0
                        obj.depthsMinMax(1) = indx;
                    else
                        obj.depthsMinMax(1) = max(indx-1,0);
                    end
                end
                % Setting the Maximum index
                [val, indx] = min(abs(obj.depths - modelConfig.depths(end)));
                if val == 0
                    obj.depthsMinMax(2) = indx;
                else
                    % Verify we are on the right side of the closest depth
                    if (obj.depths(indx) - modelConfig.depths(1)) > 0
                        obj.depthsMinMax(2) = indx;
                    else
                        obj.depthsMinMax(2) = min(indx+1,length(obj.depths));
                    end
                end

                % Assigning the closest indexes for each depth
                currIndx = 1;
                for currDepth= modelConfig.depths
                    [val, indx] = min(abs(obj.depths - currDepth));
                    if val == 0
                        % For this depth we only need one index, because is the exact depth
                        obj.depthsIndx(currIndx,:) = [indx, indx];
                    else
                        % Verify we are on the right side of the closest depth
                        if (obj.depths(indx) - currDepth) > 0
                            obj.depthsIndx(currIndx,:) = [max(indx-1,0), indx];
                        else
                            obj.depthsIndx(currIndx,:) = [indx, min(indx+1,obj.depthsMinMax(2)) ];
                        end
                    end
                    currIndx = currIndx + 1;
                end

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
                obj.U = double(ncread(readOceanFile,obj.uvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                obj.V = double(ncread(readOceanFile,obj.vvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
            end
            % Verify if we need to read the currents of the next day
            if readOceanT2
                %readOceanFileT2
                obj.UT2 = double(ncread(readOceanFileT2,obj.uvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                obj.VT2 = double(ncread(readOceanFileT2,obj.vvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
            end

            obj.currDay = modelDay;
            obj.currHour = modelHour;
         end
	end
  end
