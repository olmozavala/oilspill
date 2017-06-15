function[newLonP, newLatP] = advpartlbV2(LON,LAT,U,V,U2,V2,lonP,latP,N,DT)
% ADVPARTL FUNCTION para graficar partículas
% function[XN,YN] = advpartl(LON,LAT,U,V,lonP,latP,N,DT,RH)
% usa un Runge Kutta orden 2
%
% LON es el vector o matriz de longitudes (en grados)
% LAT el el vector o matriz de latitudes (en grados)
% U es una matriz con la componente U de la velocidad
% V es una matriz con la componente V de la velocidad
% lonP es un vector o matriz con las longitudes de las partículas
% latP es un vector o matriz con las latitudes de las partículas
% N es el número de segmentos
% DT es el incremento de tiempo en horas
% RH es la resolución horizontal de la  malla. Espera una malla uniforme (DX=cte, DY=cte)
% en latitud y longitud
%
% Si la partícula se sale del dominio se queda en la frontera
%
% Elborada por Jorge Zavala

% (lonGoM,latGoM, Up,Vp,XDerr2a,YDerr2a,24,1,0.05)
% (LON,LAT,U,V,lonP,latP,N,DT,RH)
% LON = lonGoM;
% LAT = latGoM;
% U = Up;
% V = Vp;
% lonP = XDerr2a;
% latP = YDerr2a;
% N = 24;
% DT = 1;
% RH = 0.05;

%,U,V,lonP,latP,N,DT,RH)

DeltaT = DT*3600; % Move DT to seconds
R=6371e+03;                 % Radio medio de la tierra (Gill)
RH = LON(1,2)-LON(1,1);
DeltaTeta=(2*pi/360)*RH;

[lenLat lenLon] = size(LON);

% Gets delta lat and delta lon
deltaLon = LON(1,2) - LON(1,1); 
deltaLat = LAT(2,1) - LAT(1,1);

lenLonP =size(lonP);
lenLatP =size(latP);

% Interpolate U and V to particles positions 
Upart = interp2(LON, LAT, U, lonP, latP);
Vpart = interp2(LON, LAT, V, lonP, latP);

% Move particles to dt/2 (Runge Kutta 2)
k1lat = (DeltaT*Vpart)*(180/(R*pi));
k1lon = ((DeltaT*Upart)*(180/(R*pi))).*cosd(latP);

% Make half the jump 
tempK2lat = latP + k1lat/2;
tempK2Lon = lonP + k1lon/2;

% Interpolate U and V to DeltaT/2 
Uhalf = U + (U2 - U)/2;
Vhalf = V + (V2 - V)/2;

% Interpolate U and V to New particles positions using U at dt/2
UhalfPart = interp2(LON, LAT, Uhalf, tempK2Lon, tempK2lat);
VhalfPart = interp2(LON, LAT, Vhalf, tempK2Lon, tempK2lat);

% Move particles to dt
newLatP= latP + (DeltaT*VhalfPart)*(180/(R*pi));
newLonP= lonP + ((DeltaT*UhalfPart)*(180/(R*pi))).*cosd(latP);

% TODO Improve this part
% If we have nan, then use the previous position to indicate we are out of boundaries
outIdx = isnan(newLatP) | isnan(newLonP);
newLatP(outIdx) = latP(outIdx);
newLonP(outIdx) = lonP(outIdx);

%display( strcat(num2str(lonP),' -> ', num2str(newLonP), ' ', num2str(latP), ' -> ',num2str(newLatP)));

%% Verify if we are out of domain
%outLat = find(newLatP > BBOX(4) || newLatP < BBOX(2));
%outLon = find(newLonP > BBOX(4) || newLonP < BBOX(2));
%
%% Verify if we are in water
%inWaterLat = NaN(newLatP)
%inWaterLon = NaN(newLonP)
