classdef OilSpillData 
   properties
      dates             % Dias julianos en los que hubo derrame de petroleo
      barrels           % Cantidad de petroleo en superficie
      VBU               % Cantidad de petroleo quemado
      VE                % Cantidad de petroleo evaporado
      VNW               % Cantidad de petroleo recuperado en agua
      VDB               % Cantidad de petroleo dispersado en la sub-superficie
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
