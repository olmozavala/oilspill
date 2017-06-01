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
      depthsRelativeIndx% Array of indexes corresponding to closest indexes at each depth of the particles for cutted U and V
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
      
      UWRD % This variable will ALWAYS hold the winds of the 'previous closest' timestep
      VWRD % This variable will ALWAYS hold the winds of the 'previous closest' time step
      UWRDT2 % This variable will ALWAYS hold the winds of the 'next closest' timestep 
      VWRDT2 % This variable will ALWAYS hold the winds of the 'next closest' time step
      UWRDT2minusUWRDT % This variable always has UDT2 - UD, is used to reduce computations in every iteration
      VWRDT2minusVWRDT % This variable always has VDT2 - VD, is used to reduce computations in every iteration
  end
  methods
	   function obj = VectorFields()
         % Constructor of VectorFields, only initializes some variables.
            obj.currHour = 0; % TODO, currently only works starting at hour 0
            obj.atmFilePrefix = 'Dia_'; % File prefix for the atmospheric netcdf files
            obj.oceanFilePrefix = 'archv.2010_'; % File prefix for the ocean netcdf files
            obj.uvar = 'U';
            obj.vvar = 'V';
            obj.currDay = -1;
	   end
         function obj = initDepthsIndexes(obj,readOceanFile, readOceanFileT2, readWindFile, modelConfig)
            % Read Lat,Lon and Depth from files and create meshgrids for currents and wind
            lat = double(ncread(readOceanFile,'Latitude'));
            lon = double(ncread(readOceanFile,'Longitude'));
            obj.depths = double(ncread(readOceanFile,'Depth'));
            
            % Setting the minimum and maximum indexes for the depths of the particles
            idx = 1;
            for currDepth = modelConfig.depths
                floorIdx = find( currDepth >= obj.depths, 1, 'last');
                ceilIdx = find( obj.depths >= currDepth, 1, 'first');
                % These are the index 
                obj.depthsIndx(idx,:) = [floorIdx, ceilIdx];

                % These will be the relative indexes, these are the ones used by advecta particles.
                if floorIdx == ceilIdx
                    obj.depthsRelativeIndx(idx,:) = [idx, idx];
                else
                    obj.depthsRelativeIndx(idx,:) = [idx, idx+1];
                end
                idx = idx + 1;
            end
            % Used to read the files min and max depth values
            obj.depthsMinMax = [find( modelConfig.depths(1) >= obj.depths, 1, 'last'), find( obj.depths >= modelConfig.depths(end), 1, 'first')];

            [obj.LON, obj.LAT] = meshgrid(lon,lat);
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
                firstRead = true;
                readWindT2 = true;
                readOceanT2 = true;

                obj = obj.initDepthsIndexes(readOceanFile, readOceanFileT2, readWindFile, modelConfig);
                % On the first day we read wind and currents
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

            % Obtian the proper file name for the winds (this day or the next one)
            if readNextDayWind
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay+1),'_1.nc'];
            else
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay),'_',num2str(windFileT2Num),'.nc'];
            end

            % ------------------------- READING DATA -----------------------
            % Verify if we need to read the winds and currents for the current day
            % (this will only happens the first time of all)
            if firstRead
                % Reading currents for current day
                T1 = double(ncread(readOceanFile,obj.uvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                T2 = double(ncread(readOceanFile,obj.vvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                % Cut U and V to the only depth levels that we are going to use
                obj.UD = rot90(T1(:,:,unique(obj.depthsRelativeIndx)),3);
                obj.VD = rot90(T2(:,:,unique(obj.depthsRelativeIndx)),3);

                % Reading winds for current day
                TempUW = double(ncread(readWindFile,'U_Viento'));
                TempVW = double(ncread(readWindFile,'V_Viento'));
                [obj.UWRD, obj.VWRD] = rotangle(TempUW', TempVW');
            end

            % Verify if we need to read the winds for the next day
            if readWindT2
                % Always except the FIRST time of all, we 
                % set the 'next'(previous) rotated winds, to the 'current' winds
                if ~firstRead 
                    % Save the new 'current' winds
                    obj.UWRD = obj.UWRDT2;
                    obj.VWRD = obj.VWRDT2;
                end

                TempUW = double(ncread(readWindFileT2,'U_Viento'));
                TempVW = double(ncread(readWindFileT2,'V_Viento'));

                % Obtain the new 'next' rotated winds
                [obj.UWRDT2, obj.VWRDT2] = rotangle(TempUW', TempVW');

                % Update the temporal variable that holds U(d_1) - U(d_0) Used for the interpolation
                obj.UWRDT2minusUWRDT= (obj.UWRDT2 - obj.UWRD);
                obj.VWRDT2minusVWRDT= (obj.VWRDT2 - obj.VWRD);
            end

            % Making the interpolation to the proper 'timesteps'
            if readWindT2 %THis case is when we read new wind values
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
                T1 = double(ncread(readOceanFileT2,obj.uvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                T2 = double(ncread(readOceanFileT2,obj.vvar,[1, 1, obj.depthsMinMax(1)],[Inf, Inf, obj.depthsMinMax(2)]));
                % Cut U and V to the only depth levels that we are going to use
                obj.UDT2 = rot90(T1(:,:,unique(obj.depthsRelativeIndx)),3);
                obj.VDT2 = rot90(T2(:,:,unique(obj.depthsRelativeIndx)),3);
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
