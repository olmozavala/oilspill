classdef VisualizeParticles
    properties
        currFig
        firstTime
        particleSize
        myf
        myfd
        myh
        myhd
        an
        xq
        yq
        mask
        g1
        g2
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
            %plotParticlesSingleTime(Particles, modelConfig, f, currDay - startDay)
            LiveParticles = findobj(Particles, 'isAlive',true);
            %DeadParticles = findobj(Particles, 'isAlive',false);
            if  obj.firstTime
                obj.firstTime = false;
                view(0,70) % Define the angle of view
                %zoom(1.4);
                axis tight;
                set(gca,'BoxStyle','full','Box','on');
                hold on

                obj.myf = scatter3([LiveParticles.lastLon], [LiveParticles.lastLat], ...
                    -[LiveParticles.lastDepth],obj.particleSize,modelConfig.colorByDepth([LiveParticles.lastDepthIdx],:),'filled');
                
                obj.myf.XDataMode = 'manual';
                obj.myh.XDataMode = 'manual';

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

                obj.myf.XData = [LiveParticles.lastLon];
                obj.myf.YData = [LiveParticles.lastLat];
                obj.myf.ZData = -[LiveParticles.lastDepth];
                obj.myf.CData = modelConfig.colorByDepth([LiveParticles.lastDepthIdx],:);
                
                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.myf, strcat(modelConfig.outputFolder , datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end 
         function obj = drawLiveParticles2D(obj,Particles, modelConfig, currTime)
            %plotParticlesSingleTime(Particles, modelConfig, f, currDay - startDay)
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
                obj.myf = scatter3(lons(sortedIdx), lats(sortedIdx), depths(sortedIdx) , ...
                                obj.particleSize,modelConfig.colorByComponent(components(sortedIdx),:),'filled');

                obj.myf.XDataMode = 'manual';
                obj.myh.XDataMode = 'manual';

                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            else
                obj.myf.XData = lons(sortedIdx);
                obj.myf.YData = lats(sortedIdx);
                obj.myf.ZData = depths(sortedIdx);
                obj.myf.CData = modelConfig.colorByComponent(components(sortedIdx),:);
                
                title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.myf, strcat(modelConfig.outputFolder , 'Comp', datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end 

        function obj = drawParticles2DCoastline(obj,VF, Particles,modelConfig,currTime,currHour,currDay)
            %plotParticlesSingleTime(Particles, modelConfig, f, currDay - startDay)
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
                obj.myf = scatter(lons(sortedIdx), lats(sortedIdx),...
                    obj.particleSize,modelConfig.colorByComponent(components(sortedIdx),:),'filled');
                
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
                %t1 = 101010101010101010101
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                pt = zeros(length(modelConfig.colorByComponent), 1);
                for comp=1:length(modelConfig.colorByComponent)
                    pt(comp) = scatter(NaN,NaN,2,modelConfig.colorByComponent(comp,:),'filled');
                end
                hleg1 = legend(pt,'C1','C2','C3','C4','C5','C6','C7','C8');
                
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
                
                
                obj.myf.XDataMode = 'manual';
                obj.myh.XDataMode = 'manual';
                obj.g1.XDataMode = 'manual';
                obj.g2.XDataMode = 'manual';
                
                %title(datestr(currTime,'YYYY-mm-DD  HH'));
                drawnow
            else
                obj.myf.XData = lons(sortedIdx);
                obj.myf.YData = lats(sortedIdx);
                %obj.myf.ZData = depths(sortedIdx);
                obj.myf.CData = modelConfig.colorByComponent(components(sortedIdx),:);
                
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
                
                %title(datestr(currTime,'YYYY-mm-DD  HH'));
                refreshdata
                drawnow
            end
            if modelConfig.saveImages
                saveas(obj.myf, strcat(modelConfig.outputFolder , 'Comp', datestr(currTime,'YYYY-mm-DD_HH')),'jpg');
            end
        end
    end
end
