classdef SpillByTimeStep
   properties
      % Dias julianos en los que hubo derrame de petroleo
        decay.evaporate
        decay.biodeg
        decay.burned
        decay.collected
   end
	methods
	   function obj = OilSpillData(FechasDerrame,SurfaceOil,VBU,VE,VNW,VDB)
            obj.dates = FechasDerrame;
            obj.barrels = SurfaceOil;
            obj.VBU = VBU;
            obj.VE = VE;
            obj.VNW = VNW;
	   end
	end
end
