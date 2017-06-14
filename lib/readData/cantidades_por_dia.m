function [FechasDerrame,SurfaceOil,Burned,VE,VNW,VDB] = cantidades_por_dia

datos_derrame = load('datos_derrame.csv');
YearMonthDay = datos_derrame(:,[3,1,2]);
YearMonthDayHHMMSS = [YearMonthDay,zeros(size(YearMonthDay,1),3)];
Discharge   = datos_derrame(:,4); % EstimatedDischarge
Burned  = datos_derrame(:,5); % OilBurned
Collected  = datos_derrame(:,6); % OilCollected
WaterCollected  = datos_derrame(:,7); % OilWaterCollected
SubsurfaceDispersants = datos_derrame(:,8); % VCB
% SurfaceDispersants = datos_derrame(:,9);    % VCS

% Se siguen las ecuaciones del Oil Spill Calculator
% Constantes

k1 = 0.20;  % Natural dispersion (subsurface)
k2 = 4/9;   % Chemical dispersion (suburface)
% k3 = 0.05;  % Chemical dispersion (surface)
k4 = 0.33;  % first day evaporation
k5 = 0.04;  % second day evaporation
k6 = 0.20;  % net oil fraction in skimmed oil
k7 = 0.075; % dissolution of disperse oil
% k8 = 0.05;  % natural dispesion (surface)

abarriles = 42; % 117.35/3.785;42 US gallons or 158.9873 litres
netSpilled = Discharge - Collected; % Net spill into the water column (e
netSpilled(netSpilled<0) = 0;
VCB = SubsurfaceDispersants/abarriles;
X = 90*VCB;
VDC = (1 - k7)*min(k2*X,netSpilled); %subsurface chemical dispersion
VDC(VDC<0) = 0;
Y = netSpilled - VDC./(1-k7);
VDN = (1-k7)*max(0,k1*Y);  %subsurface natural dispersion
VDB = VDC + VDN; % total subsurface dispersed oil
VNW = k6*WaterCollected; % oil fraccion in oily water
Z = netSpilled - VDB/(1-k7); % oil fraction that makes the surface
W =max(0,(1-k4)*Z-Burned);
VE = k4*Z + k5*W + k7*VDB/(1-k7); % Evaporated oil
% VNS = max(0,k8*W); %natural surface dispersion
% VCS = SurfaceDispersants/abarriles; % volumen de dispersantes en superficie
% VS = netSpilled - VDB - VNW - Burned - VE - VNS; % other oil
% VS(VS<0) = 0;
% VDS = min(20*k3*VCS,VS); %Chemical dispersed oil near the surface (checar)
FechasDerrame = datevec2doy(YearMonthDayHHMMSS)';
% Escenario derrame
SurfaceOil = netSpilled - VDB; % Petroleo neto derramado - petroleo disperso subsuperficialmente
end
