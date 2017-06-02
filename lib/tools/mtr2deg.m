% [distance_in_degrees] = mtr2deg(distance_in_meters, lat, choice)
%
% Transform a distance_in_meters into degrees of latitude (lat_deg) or
% degrees of longitude (lon_deg) as a function of the latitude (lat).
% An average Earth radius of 6371 km is considered.
%
% choice may be set to 'lat_deg' or 'lon_deg'
%    Set choice = 'lat_deg' to obtain degrees of latitude.
%    Set choice = 'lon_deg' to obtain degrees of longitude.
%
% Example:
%
%   distance_in_meters = 500;
%   lat = 28;
%
%   lat_deg = mtr2deg(distance_in_meters, lat,'lat_deg') = 0.0045
%   lon_deg = mtr2deg(distance_in_meters, lat,'lon_deg') = 0.0051
%
function [distance_in_degrees] = mtr2deg(distance_in_meters, lat, choice, R)
    % Average Earth radius in meters
    if strcmp(choice,'lat_deg')
        % Transform distance in meters into degrees of latitude
        distance_in_degrees = 180/(pi*R) * distance_in_meters;
    elseif strcmp(choice,'lon_deg')
        % Transform distance in meters into degrees of longitude
        distance_in_degrees = 180 * distance_in_meters/(pi*R*cosd(lat));
    end
end
