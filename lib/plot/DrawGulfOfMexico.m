function DrawGulfOfMexico()
    % It reads the following variables: Lat Lon ZZ (is for all mexico)
    load('Bati_Mex_GEBCO.mat');
    golfo = importdata('golfo.jpg');

    %% ------------- Display only the gulf of mexico with a texture ------
    latlim = [18 31];
    lonlim= [-98 -80];

    % Cut the values we are interested in
    LATBBOX= Lat > latlim(1);
    LATBBOX= LATBBOX & Lat < latlim(2);

    LONBBOX= Lon > lonlim(1);
    LONBBOX= LONBBOX & Lon < lonlim(2);

    Lat = Lat(LATBBOX);
    Lon = Lon(LONBBOX);
    ZZ = ZZ(LATBBOX,LONBBOX);
    % Append NaN every 2 set of coordinates
    redSizeBy = 25;
    [X map] = rgb2ind(golfo,256); % Transforms the image into a colormap and a 2D data
    colormap(map)
    surface(Lon(1:redSizeBy:end),Lat(1:redSizeBy:end),ZZ(1:redSizeBy:end,1:redSizeBy:end),...
                    'FaceColor', 'texturemap', 'EdgeColor','none','Cdata',X);
