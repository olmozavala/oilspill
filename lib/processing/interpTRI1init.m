function [InterpObject] = interpTRI1init(lon, lat, Uin)
% INTERPTRI1   Interpolate to nonstructured mesh.
%   INTERPOBJECT = INTERPTRI1INIT(LON,LAT,UIN) takes a nonstructured mesh node
%   positions in LON,LAT with values UIN in each node, and generates 
%   an interpolation object 'InterpObject' to use with scattered points.
%   LON,LAT,UIN must have the same dimensions, which correspond to the number of nodes in the mesh (with
%   each line number corresponding to the node number in the mesh). 
%
%   This function uses the matlab built-in function 'scatteredInterpolant'
%   This Function was designed to be used with ADCIRC output.
%
%   Example: lat = double(ncread(OceanFile,'y'));
%            lon = double(ncread(OceanFile,'x'));
%            UD = double(ncread(OceanFile,'uvel',[1, 1],[Inf, 1]))
%            xp = [-99.5,-99]
%            yp = [19,20]
%            Fad = interpTRI1init(lon, lat, UD, xp, yp)
%
% Create the interpolant object.
InterpObject = scatteredInterpolant(lon,lat,Uin);
InterpObject.ExtrapolationMethod = 'none';

end