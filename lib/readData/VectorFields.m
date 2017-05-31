classdef VectorFields
    % This class assumes that the currents are stored in daily files and the winds in 6hrs files
   properties
      U % U variable for current time
      V % V variable for current time
      UT2 % U variable for next time
      VT2 % V variable for next time
      UWR % U (wind rotated) variable for current time
      VWR % V (wind rotated) variable for current time
      UWRT2 % U (wind rotated) variable for current time
      VWRT2 % V (wind rotated) variable for current time
      currHour % Last hour that the model was executred
      currDay % Last day that the model was executred
      LAT % Latitude meshgrid of the currents
      LON % Longitude meshgrid of the currents
      depths % Array of depths corresponding to U and V
      depthsIndx% Array of indexes corresponding to closest indexes at each depth of the particles
  end
  properties (Access = private)
      depthsIndxLocal% Array of indexes corresponding to closest indexes at each depth of the particles

      windDeltaT = 6; % This is the delta T for the wind fields
      myEps = .01; % Modified epsilon to make it work with ceil

      depthsMinMax % Array of indexes corresponding to the minumum and maximum depth of the particles
	atmFilePrefix % File prefix for the atmospheric netcdf files
	oceanFilePrefix  % File prefix for the ocean netcdf files 

      uvar % Is the name of the variable U inside the netCDF file 
      vvar % Is the name of the variable V inside the netCDF file

      %%% These set of variables are only used to make the proper interpolation of the currents and
      % should NOT be used by external code
      UD % This variable will ALWAYS hold the currents of the 'current' day
      VD % This variable will ALWAYS hold the currents of the 'current' day
      UDT2 % This variable will ALWAYS hold the currents of the 'next' day
      VDT2 % This variable will ALWAYS hold the currents of the 'next' day
      UDT2minusUDT % This variable always has UDT2 - UD, is used to reduce computations in every iteration
      VDT2minusVDT % This variable always has VDT2 - VD, is used to reduce computations in every iteration
      
      UWRD % This variable will ALWAYS hold the winds of the 'closest' timestep
      VWRD % This variable will ALWAYS hold the winds of the 'closest' time step
      UWRDT2 % This variable will ALWAYS hold the winds of the 'next closest' timestep 
      VWRDT2 % This variable will ALWAYS hold the winds of the 'next closest' time step
      UWRDT2minusUWRDT % This variable always has UDT2 - UD, is used to reduce computations in every iteration
      VWRDT2minusVWRDT % This variable always has VDT2 - VD, is used to reduce computations in every iteration
  end
  methods
	   function obj = VectorFields()
         % Constructor of VectorFields, only initializes some variables.
			obj.currHour = 0; % TODO, currently only works starting at hour 0
			obj.currDay = -1;
                  obj.atmFilePrefix = 'Dia_'; % File prefix for the atmospheric netcdf files
                  obj.oceanFilePrefix = 'archv.2010_'; % File prefix for the ocean netcdf files
                  obj.uvar = 'U';
                  obj.vvar = 'V';
	   end
         function obj = readUV(obj, modelHour, modelDay, modelConfig)
         % Function in charge of deciding what should we read at each time step
            windFileNum = floor(modelHour/obj.windDeltaT)+1;
            windFileT2Num = ceil( (modelHour + obj.myEps)/obj.windDeltaT)+1;

            % These variables indicate if we have to read new files   
            firstRead = false;
            readWindT2 = false;
            readOceanT2 = false;
            readNextDayWind = false;

            % Create the file names 
            readOceanFile = [obj.oceanFilePrefix,sprintf('%03d',modelDay),'_00_3z.nc'];
            readOceanFileT2 = [obj.oceanFilePrefix,sprintf('%03d',modelDay+1),'_00_3z.nc'];
            readWindFile = [obj.atmFilePrefix,num2str(modelDay),'_',num2str(windFileNum),'.nc'];
            
            % -------------------- Only executed the first time of the model, reads lat,lon,depths and computes depth indexes ----------
            % Verify the first time we get data
            if obj.currDay == -1
                % On the first day we read wind and currents
                firstRead = true;
                readWindT2 = true;
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
                        obj.depthsIndxLocal(currIndx,:) = [indx, indx];
                        obj.depthsIndx = obj.depthsIndxLocal;
                    else
                        % Verify we are on the right side of the closest depth
                        if (obj.depths(indx) - currDepth) > 0
                            obj.depthsIndxLocal(currIndx,:) = [max(indx-1,0), indx];
                        else
                            obj.depthsIndxLocal(currIndx,:) = [indx, min(indx+1,obj.depthsMinMax(2)) ];
                        end
                        obj.depthsIndx = obj.depthsIndxLocal;
                    end
                    currIndx = currIndx + 1;
                end

                [obj.LON, obj.LAT] = meshgrid(lon,lat);
            else
            % -------------------- This we check every other time that is not the first time ---------------
                % Verify we haven't increase the file name (compared with the previous hour)
                if floor(modelHour/obj.windDeltaT)~= floor(obj.currHour/obj.windDeltaT)
                    readWindT2 = true;
                end

                % Verify the next time step for the wind is still in this day
                if windFileT2Num > (24/obj.windDeltaT) &&  readWindT2
                    readNextDayWind = true;
                end

                % Decide if we need to read new data for the currents
                if modelDay ~= obj.currDay
                    readOceanT2 = true;
                end
            end

            % Verify if we need to read the winds for the next day or the current day
            if readNextDayWind
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay+1),'_1.nc'];
            else
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay),'_',num2str(windFileT2Num),'.nc'];
            end

            % ----------- Reading and organizing the winds ----------------
            % Verify if we need to read the winds for the current day
            % (this will only happens the first time of all)
            if firstRead
                %readOceanFile
                tidx = 1;

                obj.UD = double(ncread(readOceanFile,obj.uvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                obj.VD = double(ncread(readOceanFile,obj.vvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));

               % 
               % for thisDepth = [unique(obj.depthsIndxLocal)]
               %     obj.UD(:,:,tidx) = double(ncread(readOceanFile,obj.uvar,[1, 1, thisDepth],[Inf, Inf, obj.depthsMinMax(2)]));
               %     obj.VD(:,:,tidx) = double(ncread(readOceanFile,obj.vvar,[1, 1, thisDepth],[Inf, Inf, obj.depthsMinMax(2)]));
               % end


                %readWindFile
                TempUW = double(ncread(readWindFile,'U_Viento'));
                TempVW = double(ncread(readWindFile,'V_Viento'));
                [obj.UWRD, obj.VWRD] = rotangle(TempUW', TempVW');
            end
            % Verify if we need to read the winds for the next day
            if readWindT2
                %readWindFileT2
                TempUW = double(ncread(readWindFileT2,'U_Viento'));
                TempVW = double(ncread(readWindFileT2,'V_Viento'));
                if ~firstRead % Always except the FIRST time of all
                    % Save the new 'current' winds
                    obj.UWRD = obj.UWRDT2;
                    obj.VWRD = obj.VWRDT2;
                end
                % Obtain the new 'next' winds
                [obj.UWRDT2, obj.VWRDT2] = rotangle(TempUW', TempVW');

                % Update the temporal variable that holds U(d_1) - U(d_0)
                obj.UWRDT2minusUWRDT= (obj.UWRDT2 - obj.UWRD);
                obj.VWRDT2minusVWRDT= (obj.VWRDT2 - obj.VWRD);
            end

            % Making the interpolation to the proper 'timesteps'
            if readWindT2
                if firstRead % Only the FIRST time of all
                    % The final U and V (winds) corresponds, in this case, to the 'current timeframe' values
                    obj.UWR = obj.UWRD;
                    obj.VWR = obj.VWRD;
                else
                    % The final U and V (winds) corresponds, in this case, to the 'previous timeframe' values
                    obj.UWR = obj.UWRT2;
                    obj.VWR = obj.VWRT2;
                end
                % Interpolate UWT2 correctly, depending on the model hour
                obj.UWRT2 = obj.UWRD + ((mod(modelHour,obj.windDeltaT)+modelConfig.timeStep)/obj.windDeltaT)*obj.UWRDT2minusUWRDT;
                obj.VWRT2 = obj.VWRD + ((mod(modelHour,obj.windDeltaT)+modelConfig.timeStep)/obj.windDeltaT)*obj.VWRDT2minusVWRDT;
            else
                % The final U and V (winds) corresponds, in this case, to the 'current timeframe' values
                obj.UWR = obj.UWRT2;
                obj.VWR = obj.VWRT2;

                % Interpolate UWT2 correctly, depending on the model hour
                obj.UWRT2 = obj.UWRD + ((mod(modelHour,obj.windDeltaT)+modelConfig.timeStep)/obj.windDeltaT)*obj.UWRDT2minusUWRDT;
                obj.VWRT2 = obj.VWRD + ((mod(modelHour,obj.windDeltaT)+modelConfig.timeStep)/obj.windDeltaT)*obj.VWRDT2minusVWRDT;
            end


            % ----------- Reading and organizing the currents ----------------
            % Verify if we need to read the currents of the next day
            if readOceanT2
                obj.UDT2 = double(ncread(readOceanFileT2,obj.uvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                obj.VDT2 = double(ncread(readOceanFileT2,obj.vvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
            end

            % Making the interpolation to the proper 'timesteps'
            if modelDay ~= obj.currDay
                % The final U and V corresponds, in this case, to the 'current day' values
                obj.U = obj.UD;
                obj.V = obj.VD;
                % Update the temporal variable that holds U(d_1) - U(d_0)
                obj.UDT2minusUDT = (obj.UDT2 - obj.UD);
                obj.VDT2minusVDT = (obj.VDT2 - obj.VD); 
                % Interpolate UT2 correctly, depending on the model hour
                obj.UT2 = obj.UD + ((modelHour+modelConfig.timeStep)/24)*obj.UDT2minusUDT;
                obj.VT2 = obj.VD + ((modelHour+modelConfig.timeStep)/24)*obj.VDT2minusVDT;
            else
                obj.U = obj.UT2;
                obj.V = obj.VT2;
                % Interpolate UT2 and VT2 correctly, depending on the model hour
                obj.UT2 = obj.UD + ((modelHour+modelConfig.timeStep)/24)*obj.UDT2minusUDT;
                obj.VT2 = obj.VD + ((modelHour+modelConfig.timeStep)/24)*obj.VDT2minusVDT;
            end

            % Update the current time that has already been executed (read in this case)
            obj.currDay = modelDay;
            obj.currHour = modelHour;
         end
	end
  end
