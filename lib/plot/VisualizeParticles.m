classdef VisualizeParticles
    properties (Access = private)
        currFig  % Pointer to the main figure that is being used to draw the particles
        firstTime % Boolean variable that indicates if is the first time we draw something
        particleSize % Int Particle size
        %myfd
        %myhd
        an % Used to make an annotation inside the figure
        xq
        yq
        mask % Holds a mask of the domain
        g1
        g2
        % Is a function handle that contains the function that will
        % be called every time step.
        myHandle
        % Is a function handle that contains the function that will
        % be used to generate the background of the figure.
        myHandleDrawBackground
        visType
    end
    methods(Static)
        function res = getLabel(totComp)
            % Gets a string of labels for the number of oil components
            % If we have 2 oil components it returns ['C1','C2']
            cellLabel = {};
            for ii = 1:totComp
                % We need to sorted in the opposite order because that is the way we plot them
                cellLabel{ii} = strcat('C',num2str(totComp+1-ii));
            end
            res = cellstr(cellLabel);
        end
    end
    methods
        function obj = VisualizeParticles(visType)
            % Constructor of the class. Creates a new visualization
            obj.currFig = figure;
            obj.firstTime = true;
            obj.particleSize = 6;
            obj.visType = visType;
            switch visType
                case 'coastline'
                    obj.myHandleDrawBackground = @DrawGulfOfMexico2D;
                case '3D'
                    obj.myHandleDrawBackground = @DrawGulfOfMexico;
                case '2D'
                    obj.myHandleDrawBackground = @DrawGulfOfMexico2D;
            end
        end
        function obj = drawBackground(obj,BBOX)
        % Draw the gulf of Mexico, depending on the visualization type
            obj.myHandleDrawBackground(BBOX)
        end
        
        function obj = drawThisTimeStep(obj,Particles, modelConfig, VF, currTime, currHour, currDay)
        % Draw the particles at one time step, depending on the visualization type
            switch obj.visType
                case 'coastline'
                    obj = obj.drawParticles2DCoastline(VF, Particles, modelConfig, currTime, currHour, currDay);
                case '3D'
                    obj = obj.drawLiveParticles3D(Particles, modelConfig, currTime);
                case '2D'
                    obj = obj.drawLiveParticles2D(Particles, modelConfig, currTime);
            end
        end
        
        function obj = drawLiveParticles3D(obj,Particles, modelConfig, currTime)
            LiveParticles = findobj(Particles, 'isAlive',true);
            %DeadParticles = findobj(Particles, 'isAlive',false);
            if  obj.firstTime
                obj.firstTime = false;
                view(0,70) % Define the angle of view
                %zoom(1.4);
                axis tight;
                set(gca,'BoxStyle','full','Box','on');
                hold on
                
                obj.currFig = scatter3([LiveParticles.lastLon], [LiveParticles.lastLat], ...
                    -[LiveParticles.lastDepth],obj.particleSize,modelConfig.colorByDepth([LiveParticles.lastDepthIdx],:),'filled');
                
                obj.currFig.XDataMode = 'manual';
                
                %obj.myfd = scatter3([DeadParticles.lastLon], [DeadParticles.lastLat], ...
                %                    -[DeadParticles.lastDepth],obj.particleSize,'w','filled');
                
                %obj.myfd.XDataMode = 'manual';
                %obj.myhd.XDataMode = 'manual';
                
                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            else
                %obj.myfd.XData = [DeadParticles.lastLon];
                %obj.myfd.YData = [DeadParticles.lastLat];
                %obj.myfd.ZData = -[DeadParticles.lastDepth];
                
                obj.currFig.XData = [LiveParticles.lastLon];
                obj.currFig.YData = [LiveParticles.lastLat];
                obj.currFig.ZData = -[LiveParticles.lastDepth];
                obj.currFig.CData = modelConfig.colorByDepth([LiveParticles.lastDepthIdx],:);
                
                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.currFig, strcat(modelConfig.outputFolder , datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end
        function obj = drawLiveParticles2D(obj,Particles, modelConfig, currTime)
            LiveParticles = findobj(Particles, 'isAlive',true);
            LiveParticles = findobj(LiveParticles, 'lastDepth',0);
            
            lons = [LiveParticles.lastLon];
            lats = [LiveParticles.lastLat];
            depths = [LiveParticles.lastDepth];
            components = [LiveParticles.component];
            [del sortedIdx] = sort(components,'ascend');
            
            if  obj.firstTime
                obj.firstTime = false;
                
                view(0,90) % Define the angle of view
                set(gca,'BoxStyle','full','Box','on');
                hold on
                %obj.currFig = scatter3(lons(sortedIdx), lats(sortedIdx), depths(sortedIdx) , ...
                %obj.particleSize,modelConfig.colorByComponent(components(sortedIdx),:),'filled');
                
                % Drawing the particles as points
                obj.currFig = gscatter(lons(sortedIdx), lats(sortedIdx),components(sortedIdx), modelConfig.colorByComponent, '.',obj.particleSize);
                legend(obj.currFig, VisualizeParticles.getLabel(modelConfig.totComponents));
                % Seting the colors of the particles by component and defining a manual generation of plots
                for ic = 1:modelConfig.totComponents
                    obj.currFig(ic).Color = modelConfig.colorByComponent(modelConfig.totComponents+1-ic,:);   % Colors by each component
                    obj.currFig(ic).XDataMode = 'manual';
                end
 
                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            else
                % Update the positions of each particle. By component.
                % We need to invert the order of the components in order to display on top component 1, then 2, etc. 
                for ic = 1:modelConfig.totComponents
                    currIdx = components == ic;
                    obj.currFig(modelConfig.totComponents+1-ic).XData = lons(currIdx);
                    obj.currFig(modelConfig.totComponents+1-ic).YData = lats(currIdx);
                end

                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.currFig, strcat(modelConfig.outputFolder , 'Comp', datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end
        
        function obj = drawParticles2DCoastline(obj,VF, Particles,modelConfig,currTime,currHour,currDay)
            % Gets the live particles with depth 0 (only drawing surface particles)
            LiveParticles = findobj(Particles, 'isAlive',true);
            LiveParticles = findobj(LiveParticles, 'lastDepth',0);
            
            % Obtains the last positions of the particles
            lons = [LiveParticles.lastLon];
            lats = [LiveParticles.lastLat];
            depths = [LiveParticles.lastDepth];
            components = [LiveParticles.component];
            [del sortedIdx] = sort(components,'descend');
            
            if  obj.firstTime
                obj.firstTime = false;
                
                %                 latlim = [min([LiveParticles.lastLat])-0.5 max([LiveParticles.lastLat])+0.5];
                %                 lonlim= [min([LiveParticles.lastLon])-0.5 max([LiveParticles.lastLon])+0.5];
                lonlim = [min(VF.LON) max(VF.LON)];
                latlim = [min(VF.LAT) max(VF.LAT)];
                %axis([lonlim(1) lonlim(2) latlim(1) latlim(2)]);
                axis([lonlim(1) -94 latlim(1) latlim(2)]);
                %                 axis([lonlim(1) -94 latlim(1) latlim(2)]);
                %                  axis([-97 -95.5 18.5 20.5]);
                %                 axis([-96.2 -96 19.10 19.26]);
                
                hold on
                
                % Drawing the particles as points
                obj.currFig = gscatter(lons(sortedIdx), lats(sortedIdx),components(sortedIdx), modelConfig.colorByComponent, '.',obj.particleSize);
                legend(obj.currFig, VisualizeParticles.getLabel(modelConfig.totComponents));
                % Seting the colors of the particles by component and defining a manual generation of plots
                for ic = 1:modelConfig.totComponents
                    obj.currFig(ic).Color = modelConfig.colorByComponent(modelConfig.totComponents+1-ic,:);   % Colors by each component
                    obj.currFig(ic).XDataMode = 'manual';
                end
                
                % Setting titles and labels
                title('Oil Dispersion by component')
                xlabel('Longitude')
                ylabel('Latitude')
                set(gca, 'YTickLabel', num2str(get(gca,'YTick')','%0.1f'))
                set(gca, 'XTickLabel', num2str(get(gca,'XTick')','%0.1f'))

                % Drawing annotation of day and hour 
                dim = [0.24 0.01 0.2 0.2];
                formato = 'YYYY-mm-DD';
                daystr = toSerialDate(modelConfig.startDate.Year,currDay,currHour);
                fechastr = datestr(daystr,formato);
                str = sprintf('Date %s, Hour %d', fechastr, currHour);
                obj.an = annotation('textbox',dim,'String',str,'FitBoxToText','on','BackgroundColor','w');
                
                % Makes a grid
                [obj.xq,obj.yq] = meshgrid(lonlim(1):.1:-92, latlim(1):.1:latlim(2));
                [s1 s2] = size(obj.xq);
                
                % Convert grid into 1D array
                xqv = reshape(obj.xq,s1*s2,1);
                yqv = reshape(obj.yq,s1*s2,1);

                % Verify those positions are inside the domain
                [dentro, xpos, ypos] = insideDomain(xqv,yqv,xqv,yqv,VF);

                % Makes a mask with the grid points that are inside the domain
                obj.mask = reshape(dentro,s1,s2);
                

                Uq = griddata(VF.LON,VF.LAT,VF.U,obj.xq,obj.yq).*obj.mask;
                Vq = griddata(VF.LON,VF.LAT,VF.V,obj.xq,obj.yq).*obj.mask;
                obj.g1 = quiver(obj.xq,obj.yq,Uq,Vq,1.5);
                
                UWRq = griddata(VF.LON,VF.LAT,VF.UWR,obj.xq,obj.yq).*obj.mask;
                VWRq = griddata(VF.LON,VF.LAT,VF.VWR,obj.xq,obj.yq).*obj.mask;
                obj.g2 = quiver(obj.xq,obj.yq,UWRq,VWRq,1.5);
                
                obj.g1.XDataMode = 'manual';
                obj.g2.XDataMode = 'manual';
                
                drawnow
            else

                % Update the positions of each particle. By component.
                % We need to invert the order of the components in order to display on top component 1, then 2, etc. 
                for ic = 1:modelConfig.totComponents
                    currIdx = components == ic;
                    obj.currFig(modelConfig.totComponents+1-ic).XData = lons(currIdx);
                    obj.currFig(modelConfig.totComponents+1-ic).YData = lats(currIdx);
                end

                Uq = griddata(VF.LON,VF.LAT,VF.U,obj.xq,obj.yq).*obj.mask;
                Vq = griddata(VF.LON,VF.LAT,VF.V,obj.xq,obj.yq).*obj.mask;
                % Updates the vectos for the currents
                obj.g1.UData = Uq;
                obj.g1.VData = Vq;
                
                UWRq = griddata(VF.LON,VF.LAT,VF.UWR,obj.xq,obj.yq).*obj.mask;
                VWRq = griddata(VF.LON,VF.LAT,VF.VWR,obj.xq,obj.yq).*obj.mask;
                % Updates the vectos for the winds
                obj.g2.UData = UWRq;
                obj.g2.VData = VWRq;
                
                daystr = toSerialDate(modelConfig.startDate.Year,currDay,currHour);
                formato = 'dd-mm-yyyy';
                fechastr = datestr(currTime,'YYYY-mm-DD');
                str = sprintf('Date %s, Hour %.1f', fechastr, currHour);
                obj.an.String = str;
                
                refreshdata
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.currFig(1), strcat(modelConfig.outputFolder ,'Comp',  datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end
    end
end
