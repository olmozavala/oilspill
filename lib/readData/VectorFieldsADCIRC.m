classdef VectorFieldsADCIRC
    % This class assumes that the currents are stored in daily files with
    % 24 hours data and the winds in daily files with 24 hours. It differs
    % from the vanilla VectorFields class in that it reads data from a
    % nonstructured mesh, like ADCIRC fort.64 and fort.74 output.
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
        LAT % Latitude (in this case are the set of nodes)
        LON % Longitude (in this case are the set of nodes)
        depths % Vector of depths corresponding to U and V, its all surface.
        depthsMinMax % Array of indexes corresponding to the minumum and maximum depth of the particles
        depthsIndx% Array of indexes corresponding to closest indexes at each depth of the particles
        depthsRelativeIndx% Array of indexes corresponding to closest indexes at each depth of the particles for cutted U and V
        atmFilePrefix % File prefix for the atmospheric netcdf files
        oceanFilePrefix  % File prefix for the ocean netcdf files
        uvar % Is the name of the variable U inside the netCDF file
        vvar % Is the name of the variable V inside the netCDF file
        BBOX   % This is an array containing the boundary box of our model [minlat minlon maxlat maxlon]

        %===============ADCIRC EXCLUSIVE==============
        ELE % Nodes of an Element (an element is a triangle)
        E2E5 %Table of the Elements that surround an element at 5 levels (neighbors of each element, up to 4 neighbors)
        N2E  % Table of the Elements that surround a node  
        CostaX % Node longitude of Coastline of mesh defined by FORT.14 (Longitude).
        CostaY % Node latitude of Coastline of mesh defined by FORT.14 (Latitude))
        TR %Triangulation (nodes of each element)
        MeshInterp %Interp object for future interpolation
        %==============================================
    end
    properties (Access = private)
        
        currentDeltaT = 1; %This is the delta T for the ocean current fields
        windDeltaT = 1; % This is the delta T for the wind fields (hours)
        myEps = .01; % Modified epsilon to make it work with ceil
        
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
        function obj = VectorFieldsADCIRC()
            obj.currHour = 0; % TODO, currently only works starting at hour 0
            obj.currDay = -1;
            obj.atmFilePrefix = 'fort.74.';
            obj.oceanFilePrefix = 'fort.64.';
            obj.uvar ='u-vel';
            obj.vvar ='v-vel';
        end
        function obj = initDepthsIndexes(obj,readOceanFile, readOceanFileT2, readWindFile, modelConfig)
            % Read Lat,Lon and Depth from files and create meshgrids for currents and wind
            lat = double(ncread(readOceanFile,'y'));
            lon = double(ncread(readOceanFile,'x'));

            % Read Lat,Lon and Depth from files and create meshgrids for currents and wind
            obj.BBOX = [min(lat) min(lon) max(lat) max(lon)];

            %===============ADCIRC EXCLUSIVE==============
            %ele now has the elements from the FORT.14 mesh. Since
            %ADCIRC gives 2D outputs, depths are all zero. 
            ele = double(ncread(readOceanFile,'element'));
            %                 pele(1:max(size(ele)))=0;
            % Since ADCIRC 2D has only surface velocities, we create a
            % zero vector for 'depths'.
            obj.depths = zeros(1,1);
            %==============================================

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

            %===============ADCIRC EXCLUSIVE==============
            %We cannot make a lat/lon meshgrid with the nonstructured
            %mesh, so instead we generate vectors for each element. 
            obj.LON = lon;
            obj.LAT = lat;
            obj.ELE = ele';
            %In here we read the coast nodes to check if particles are
            %inside the domain.
            Costa = dlmread('costa.txt');
            obj.CostaX = obj.LON(Costa);
            obj.CostaY = obj.LAT(Costa);
            clear Costa
            P = [obj.LON obj.LAT];
            obj.TR = triangulation(obj.ELE,P);
            obj.MeshInterp = interpTRI1init(obj.LON,obj.LAT,zeros(length(obj.LON),1));

            %==============================================
            %                 obj.PELE = pele';
        end
        function obj = readUV(obj, modelHour, modelDay, modelConfig)
            windFileNum = floor(modelHour/obj.windDeltaT)+1;
            windFileT2Num = ceil( (modelHour + obj.myEps)/obj.windDeltaT)+1;
            
            %===============ADCIRC EXCLUSIVE==============
            %We allow to have several oceanFiles, since output has higher
            %frequency than the previously used ocean model.
            oceanFileNum = floor(modelHour/obj.currentDeltaT)+1;
            oceanFileT2Num = ceil( (modelHour + obj.myEps)/obj.currentDeltaT)+1;
            %==============================================
            
            % These variables indicate if we have to read new files
            firstRead = false;
            readWindT2 = false;
            readOceanT2 = false;
            readNextDayWind = false;
            
            %===============ADCIRC EXCLUSIVE==============
            %Necessary changes to read several ocean files.
            readNextDayOcean = false;
            
            % Create the file names
            readOceanFile = [obj.oceanFilePrefix,sprintf('%03d',modelDay),'.nc'];
            readOceanFileT2 = [obj.oceanFilePrefix,sprintf('%03d',modelDay+1),'.nc'];
            readWindFile = [obj.atmFilePrefix,num2str(modelDay),'.nc'];
            %==============================================
            
            % -------------------- Only executed the first time of the model, reads lat,lon,depths and computes depth indexes ----------
            % Verify the first time we get data
            if obj.currDay == -1
                % On the first day we read wind and currents
                firstRead = true;
                readWindT2 = true;
                readOceanT2 = true;
                
                obj = obj.initDepthsIndexes(readOceanFile, readOceanFileT2, readWindFile, modelConfig);
            else
                % -------------------- This we check every other time that is not the first time ---------------
                % Verify we haven't increase the file name
                if floor(modelHour/obj.windDeltaT)~= floor(obj.currHour/obj.windDeltaT)
                    readWindT2 = true;
                end
                
                %===============ADCIRC EXCLUSIVE==============
                % Same, but for ocean currents
                if floor(modelHour/obj.currentDeltaT)~= floor(obj.currHour/obj.currentDeltaT)
                    readOceanT2 = true;
                end
                %==============================================
                
                % Verify the next time step for the wind is still in this day
                if windFileT2Num > (24/obj.windDeltaT) &&  (mod(modelHour,obj.windDeltaT) == 0 )
                    readNextDayWind = true;
                    readWindT2 = true;
                end
                
                %===============ADCIRC EXCLUSIVE==============
                % Verify the next time step for the ocean currents is still in this day
                if oceanFileT2Num > (24/obj.currentDeltaT) &&  (mod(modelHour,obj.currentDeltaT) == 0 )
                    readNextDayOcean = true;
                    readOceanT2 = true;
                end
                %==============================================
                
            end
            
            %===============ADCIRC EXCLUSIVE==============
            %The method to read the files changed to reflect changes in
            %file notation for ADCIRC.
            % Verify if we need to read the winds for the next day or the current day
            if readNextDayWind
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay+1),'.nc'];
            else
                readWindFileT2 = [obj.atmFilePrefix,num2str(modelDay),'.nc'];
            end
            
            % Verify if we need to read the currents for the next day or the current day
            if readNextDayOcean
                readOceanFileT2 = [obj.oceanFilePrefix,num2str(modelDay+1),'.nc'];
            else
                readOceanFileT2 = [obj.oceanFilePrefix,num2str(modelDay),'.nc'];
            end
            %==============================================
            
            % ----------- Reading and organizing the winds ----------------
            % Verify if we need to read the winds for the current day
            % (this will only happens the first time of all)
            
            %===============ADCIRC EXCLUSIVE==============
            %Since we have no depth on the variables, we take out the depth
            %index to make 2D variables, both in wind and Ocean.
            if firstRead
                %readOceanFile
                obj.UD = double(ncread(readOceanFile,obj.uvar,[1, 1],[Inf, 1]));
                obj.VD = double(ncread(readOceanFile,obj.vvar,[1, 1],[Inf, 1]));

                % Making nan the currents with 0 value. Makes it easier all the following computations
                % TODO verify that both, U and V are 0
                nanIdx = unique(cat(1,find(obj.UD== 0) , find(obj.VD== 0)));
                obj.UD(nanIdx) = nan;
                obj.VD(nanIdx) = nan;
                
                %readWindFile
                TempUW = double(ncread(readWindFile,'windx',[1, 1],[Inf, 1]));
                TempVW = double(ncread(readWindFile,'windy',[1, 1],[Inf, 1]));
                %[obj.UWRD, obj.VWRD] = rotangle(TempUW', TempVW');
                [obj.UWRD, obj.VWRD] = rotangle(TempUW, TempVW);
            end
            %==============================================
            
            % Verify if we need to read the winds for the next day
            if readWindT2
                %readWindFileT2
                
                %===============ADCIRC EXCLUSIVE==============
                %Since the index WindFileT2Num will have illegal value on
                %day change, we need to use the first one of the next day.
                if readNextDayWind
                    TempUW = double(ncread(readWindFileT2,'windx',[1, 1],[Inf, 1]));
                    TempVW = double(ncread(readWindFileT2,'windy',[1, 1],[Inf, 1]));
                else
                    TempUW = double(ncread(readWindFileT2,'windx',[1, windFileT2Num],[Inf, 1]));
                    TempVW = double(ncread(readWindFileT2,'windy',[1, windFileT2Num],[Inf, 1]));
                end
                if ~firstRead % Always except the FIRST time of all
                    % Save the new 'current' winds
                    obj.UWRD = obj.UWRDT2;
                    obj.VWRD = obj.VWRDT2;
                end
                % Obtain the new 'next' winds
                [obj.UWRDT2, obj.VWRDT2] = rotangle(TempUW, TempVW);
                %==============================================
                
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
                %===============ADCIRC EXCLUSIVE==============
                %Since the index OceanFileT2Num will have illegal value on
                %day change, we need to use the first one of the next day.
                if readNextDayOcean
                    obj.UDT2 = double(ncread(readOceanFileT2,obj.uvar,[1, 1],[Inf, 1]));
                    obj.VDT2 = double(ncread(readOceanFileT2,obj.vvar,[1, 1],[Inf, 1]));
                else
                    obj.UDT2 = double(ncread(readOceanFileT2,obj.uvar,[1, oceanFileT2Num],[Inf, 1]));
                    obj.VDT2 = double(ncread(readOceanFileT2,obj.vvar,[1, oceanFileT2Num],[Inf, 1]));
                end
                if ~firstRead % Always except the FIRST time of all
                    % Save the new 'current' currents
                    obj.UD = obj.UDT2;
                    obj.VD = obj.VDT2;
                end
                % Obtain the new 'next' winds
                %[obj.UDT2, obj.VDT2] = rotangle(TempUW, TempVW);

                % Making nan the currents with 0 value. Makes it easier all the following computations
                % TODO verify that both, U and V are 0
                nanIdx = unique(cat(1,find(obj.UDT2 == 0) , find(obj.VDT2 == 0)));
                obj.UDT2(nanIdx) = nan;
                obj.VDT2(nanIdx) = nan;
                
                % Update the temporal variable that holds U(d_1) - U(d_0)
                obj.UDT2minusUDT = (obj.UDT2 - obj.UD);
                obj.VDT2minusVDT = (obj.VDT2 - obj.VD);
                
            end
            
            if readOceanT2
                if firstRead % Only the FIRST time of all
                    % The final U and V (winds) corresponds, in this case, to the 'current timeframe' values
                    obj.U = obj.UD;
                    obj.V = obj.VD;
                else
                    % The final U and V (winds) corresponds, in this case, to the 'previous timeframe' values
                    obj.U = obj.UDT2;
                    obj.V = obj.VDT2;
                end
                % Interpolate UWT2 correctly, depending on the model hour
                obj.UT2 = obj.UD + ((mod(modelHour,obj.currentDeltaT)+modelConfig.timeStep)/obj.currentDeltaT)*obj.UDT2minusUDT;
                obj.VT2 = obj.VD + ((mod(modelHour,obj.currentDeltaT)+modelConfig.timeStep)/obj.currentDeltaT)*obj.VDT2minusVDT;
            else
                % The final U and V (winds) corresponds, in this case, to the 'current timeframe' values
                obj.U = obj.UT2;
                obj.V = obj.VT2;
                
                % Interpolate UWT2 correctly, depending on the model hour
                obj.UT2 = obj.UD + ((mod(modelHour,obj.currentDeltaT)+modelConfig.timeStep)/obj.currentDeltaT)*obj.UDT2minusUDT;
                obj.VT2 = obj.VD + ((mod(modelHour,obj.currentDeltaT)+modelConfig.timeStep)/obj.currentDeltaT)*obj.VDT2minusVDT;
            end
            %==============================================
            
            % Update the current time that has already been executed (read in this case)
            obj.currDay = modelDay;
            obj.currHour = modelHour;
        end
        %===============ADCIRC EXCLUSIVE==============
        %This method allows to read ADCIRC results exclusive data.
        function obj = readLists(obj)
            load el2el5.mat
            obj.E2E5 = el2el5;
            n2e = dlmread('NODE2EL.TBL');
            obj.N2E = n2e;
            
            clear el2el5 n2e
        end
        %==============================================
    end
end
