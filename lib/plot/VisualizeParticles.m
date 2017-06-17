classdef VisualizeParticles
    properties (Access = private)
        currFig  % Pointer to the main figure that is being used to draw the particles
        firstTime % Boolean variable that indicates if is the first time we draw something
        particleSize % Int Particle size 
        %myfd
        %myhd
        an % Used to make an annotation inside the figure
        leg % Used to make a custom legend inside the figure
        xq
        yq
        mask % Holds a mask of the domain 
        g1
        g2
    end
    methods(Static)
        function res = getLabel(totComp)
            cellLabel = {};
            for ii = 1:totComp
                cellLabel{ii} = strcat('C',num2str(ii));
            end
            res = cellstr(cellLabel);
        end
    end
    methods
        function obj = VisualizeParticles()
            % Constructor of the class. Creates a new visualization
            obj.currFig = figure;
            obj.firstTime = true;
            obj.particleSize = 6;
	   end
	   function obj = drawGulf(obj)
         % Constructor of the class. Creates a new visualization
            DrawGulfOfMexico();
         end

        function obj = drawGulf2d(obj)
            DrawGulfOfMexico2D();
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
            [del sortedIdx] = sort(components,'descend');

            if  obj.firstTime
                obj.firstTime = false;

                view(0,90) % Define the angle of view
                axis tight;
                set(gca,'BoxStyle','full','Box','on');
                hold on
                %obj.currFig = scatter3(lons(sortedIdx), lats(sortedIdx), depths(sortedIdx) , ...
                                %obj.particleSize,modelConfig.colorByComponent(components(sortedIdx),:),'filled');

                obj.currFig = gscatter(lons(sortedIdx), lats(sortedIdx),components(sortedIdx), modelConfig.colorByComponent, '.',obj.particleSize);
                obj.currFig.XDataMode = 'manual';

                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            else
                obj.currFig.XData = lons(sortedIdx);
                obj.currFig.YData = lats(sortedIdx);
                obj.currFig.ZData = depths(sortedIdx);
                obj.currFig.CData = modelConfig.colorByComponent(components(sortedIdx),:);
                
                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.currFig, strcat(modelConfig.outputFolder , 'Comp', datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end 

        function obj = drawParticles2DCoastline(obj,VF, Particles,modelConfig,currTime,currHour,currDay)
            LiveParticles = findobj(Particles, 'isAlive',true);
            LiveParticles = findobj(LiveParticles, 'lastDepth',0);
            
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
                
                obj.currFig = gscatter(lons(sortedIdx), lats(sortedIdx),components(sortedIdx), modelConfig.colorByComponent, '.',obj.particleSize);
                legend(obj.currFig, VisualizeParticles.getLabel(modelConfig.totComponents));

                title('Oil Dispersion by component')
                xlabel('Longitude')
                ylabel('Latitude')
                set(gca, 'YTickLabel', num2str(get(gca,'YTick')','%0.1f'))
                set(gca, 'XTickLabel', num2str(get(gca,'XTick')','%0.1f'))
                %%%%%%%%%%%%For day and hour box%%%%%%%%%
                dim = [0.24 0.01 0.2 0.2];
                formato = 'YYYY-mm-DD';
                daystr = toSerialDate(modelConfig.startDate.Year,currDay,currHour);
                fechastr = datestr(daystr,formato);
                str = sprintf('Date %s, Hour %d', fechastr, currHour);
                obj.an = annotation('textbox',dim,'String',str,'FitBoxToText','on','BackgroundColor','w');
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                [obj.xq,obj.yq] = meshgrid(lonlim(1):.1:-92, latlim(1):.1:latlim(2));
                [s1 s2] = size(obj.xq);
                
                xqv = reshape(obj.xq,s1*s2,1);
                yqv = reshape(obj.yq,s1*s2,1);
                [dentro, xpos, ypos] = insideDomain(xqv,yqv,xqv,yqv);
                obj.mask = reshape(dentro,s1,s2);
                
                Uq = griddata(VF.LON,VF.LAT,VF.U,obj.xq,obj.yq).*obj.mask;
                Vq = griddata(VF.LON,VF.LAT,VF.V,obj.xq,obj.yq).*obj.mask;
                obj.g1 = quiver(obj.xq,obj.yq,Uq,Vq,1.5);
               
                UWRq = griddata(VF.LON,VF.LAT,VF.UWR,obj.xq,obj.yq).*obj.mask;
                VWRq = griddata(VF.LON,VF.LAT,VF.VWR,obj.xq,obj.yq).*obj.mask;
                obj.g2 = quiver(obj.xq,obj.yq,UWRq,VWRq,1.5);  
                
                for ic = 1:modelConfig.totComponents
                    obj.currFig(ic).XDataMode = 'manual';
                end
                obj.g1.XDataMode = 'manual';
                obj.g2.XDataMode = 'manual';
                
                ht = text(5, 0.5, {'{\color{red} o } Red', '{\color{blue} o } Blue', '{\color{black} o } Black'}, 'EdgeColor', 'k');
                drawnow
            else
                for ic = 1:modelConfig.totComponents
                    currIdx = components == ic;
                    obj.currFig(ic).XData = lons(currIdx);
                    obj.currFig(ic).YData = lats(currIdx);
                end
                
                Uq = griddata(VF.LON,VF.LAT,VF.U,obj.xq,obj.yq).*obj.mask;
                Vq = griddata(VF.LON,VF.LAT,VF.V,obj.xq,obj.yq).*obj.mask;
                obj.g1.UData = Uq;
                obj.g1.VData = Vq;
                
                UWRq = griddata(VF.LON,VF.LAT,VF.UWR,obj.xq,obj.yq).*obj.mask;
                VWRq = griddata(VF.LON,VF.LAT,VF.VWR,obj.xq,obj.yq).*obj.mask;
                obj.g2.UData = UWRq;
                obj.g2.VData = VWRq;   
                
                daystr = toSerialDate(modelConfig.startDate.Year,currDay,currHour);
                formato = 'dd-mm-yyyy';
                fechastr = datestr(currTime,'YYYY-mm-DD');
                str = sprintf('Date %s, Hour %.1f', fechastr, currHour);
                obj.an.String = str;
                obj.leg = text(5.1,0.78, '*', 'Color', 'blue');
                
                refreshdata
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.currFig(1), strcat(modelConfig.outputFolder ,'Comp',  datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end
    end
end
