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
   end
	methods
	   function obj = VectorFields(currHour)
			obj.currHour = currHour;
			obj.currDay = -1;
	   end
         function obj = readUV(obj, fixedWindDeltaT, modelHour, modelDay)

            eps = .01; % Modified epsilon to make it work with ceil
            fixedWindDeltaT = 1;
            atmInputFolder  = '/home/olmozavala/Desktop/PETROLEO_OUT/'; % Input folder where de atm data is stored
		oceanInputFolder  = '/home/olmozavala/Desktop/PETROLEO_OUT/'; % Input folder where de oceanic data is stored
		atmFilePrefix  = 'Dia_'; % File prefix for the atmospheric netcdf files
		oceanFilePrefix  = 'archv.2010_'; % File prefix for the ocean netcdf files

            windFileNum = floor(modelHour/fixedWindDeltaT)+1;
            windFileT2Num = ceil( (modelHour + eps)/fixedWindDeltaT)+1;

            readWind = false;
            readWindT2 = false;
            readOcean = false;
            readOceanT2 = false;
            readNextDayWind = false;

            idx_depth_1  = 10;
            
            % Verify the first time we get data
            if modelHour == 0 && obj.currDay == -1
                % On the first day we read wind and currents
                readWind = true;
                readWindT2 = true;
                readOcean = true;
                readOceanT2 = true;
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


            % Reading data
            readOceanFile = [oceanInputFolder,oceanFilePrefix,sprintf('%03d',modelDay),'_00_3z.nc'];
            readOceanFileT2 = [oceanInputFolder,oceanFilePrefix,sprintf('%03d',modelDay+1),'_00_3z.nc'];
            readWindFile = [atmInputFolder, atmFilePrefix,num2str(modelDay),'_',num2str(windFileNum),'.nc'];

            % Verify if we need to read the winds for the next day or the current day
            if readNextDayWind
                readWindFileT2 = [atmInputFolder, atmFilePrefix,num2str(modelDay+1),'_1.nc'];
                obj.UW = obj.UWT2;
                obj.VW = obj.VWT2;
            else
                readWindFileT2 = [atmInputFolder, atmFilePrefix,num2str(modelDay),'_',num2str(windFileT2Num),'.nc'];
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
                obj.U = double(ncread(readOceanFile,'U',[1, 1, idx_depth_1],[Inf, Inf, 1])');
                obj.V = double(ncread(readOceanFile,'V',[1, 1, idx_depth_1],[Inf, Inf, 1])');
            end
            % Verify if we need to read the currents of the next day
            if readOceanT2
                %readOceanFileT2
                obj.UT2 = double(ncread(readOceanFileT2,'U',[1, 1, idx_depth_1],[Inf, Inf, 1])');
                obj.VT2 = double(ncread(readOceanFileT2,'V',[1, 1, idx_depth_1],[Inf, Inf, 1])');
            end

            obj.currDay = modelDay;
            obj.currHour = modelHour;
         end
	end
  end
