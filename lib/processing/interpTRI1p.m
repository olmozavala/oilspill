function [Uout] = interpTRI1p(Uin, xp, yp,F)
% INTERPTRI1   Interpolate to nonstructured mesh.
%   UOUT = INTERPTRI1P(UIN,X,Y,F) takes a nonstructured mesh with values UIN in each node, and interpolates the
%   value to every X,Y desired point with the F interpolant object,
%   generated previously with interpTRI1init(). LON,LAT,UIN must have the same
%   dimensions, which correspond to the number of nodes in the mesh (with
%   each line number corresponding to the node number in the mesh). XP and
%   YP are vectors with the same dimension with each other, but not
%   necessarily the same dimension as LON,LAT. 
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
%            [U_xp_yp] = interpTRI1(UD, xp, yp, Fad)


% Update the interpolant object U field  
    F.Values = Uin;

% Evaluate the interpolant at query locations (xp,yp).
    Uout = F(xp,yp);

end