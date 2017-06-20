function DrawGulfOfMexico2D(BBOX)
    % It reads the following variables: Lat Lon ZZ (is for all mexico)
%     load('Bati_Mex_GEBCO.mat');
%     golfo = importdata('golfo.jpg');
    %Load coastline data
    load('linea_costa_divpol.mat');
    mexico = linea_costa;

    %% ------------- Display only the gulf of mexico with a texture ------
    latlim = [BBOX(1) BBOX(3)];
    lonlim= [BBOX(2) BBOX(4)];

    %Draw coastline for values
    plot(mexico(:,1),mexico(:,2),'k','LineWidth',1); 
    axis equal
    %Zoom to area of interest
    axis([lonlim(1) lonlim(2) latlim(1) latlim(2)])
    % Append NaN every 2 set of coordinates
%     redSizeBy = 25;
%     [X map] = rgb2ind(golfo,256); % Transforms the image into a colormap and a 2D data
%     colormap(map)
%     surface(Lon(1:redSizeBy:end),Lat(1:redSizeBy:end),ZZ(1:redSizeBy:end,1:redSizeBy:end),...
%                     'FaceColor', 'texturemap', 'EdgeColor','none','Cdata',X);
%     view(2);

