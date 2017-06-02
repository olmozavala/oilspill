classdef VisualizeParticles
   properties
      currFig 
      firstTime
      particleSize
      myf
      myfd
      myh
      myhd
   end
	methods
	   function obj = VisualizeParticles()
         % Constructor of the class. Creates a new visualization
            obj.currFig = figure;
            obj.firstTime = true;
            obj.particleSize = 4;
	   end
	   function obj = drawGulf(obj)
         % Constructor of the class. Creates a new visualization
            DrawGulfOfMexico();
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

	end
end
