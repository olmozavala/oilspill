function [XDerr, YDerr] = oilspill_subsuperficie(Depths, Profundidad,dia_inicio,dia_fin,ultimo_dia_derrame,...
    lon_derrame,lat_derrame,FechasDerrame,VDB,fracc_VDB,outputFolder,componentes,Decaimiento,t_degradacion)

close all
profundidad = num2str(Profundidad);
fprintf(['Haciendo caso subsuperficial de ',profundidad,' m... \n'])
% Rutas
Ruta_figuras = [pwd,'/',outputFolder,'/figuras_superficie/'];
mkdir(Ruta_figuras);
filePrefix   = '/archv.2010_';

% Inicializacion de vectores de posicion para cada clase de petroleo
% Posicion de particulas en agua
Xagua       = cell(1,8);  
Yagua       = Xagua;
% Posicion X de particulas en tierra
Xtierra     = Xagua;  
Ytierra     = Xagua;
% Fechas de las particulas
VecFechas   = Xagua;  
p_degradado = Xagua;  % Petroleo degradado
p_tierra    = Xagua;  % Petroleo en tierra

% Cargar linea de costa global
barra_color = cell2mat(struct2cell(load('barra_color.mat')));
mundo = load('mundo.dat');

% Generar isobata de la profundidad de simulacion
ra1=sprintf('%03d',dia_inicio);

fileName = [filePrefix,ra1,'_00_3z.nc'];
Lon   = double(ncread(fileName,'Longitude'));
Lat   = double(ncread(fileName,'Latitude'));

% Creates the meshgrid with the LAT and LON
[LON,LAT] = meshgrid(Lon,Lat);
BBOX = [min(Lon), min(Lat), max(Lon), max(Lat)]

% Variable para las imagenes de acumulativo
Mat2 = nan(length(Lat),length(Lon),8);

% Reads all depths from file
depth = ncread(fileName,'Depth');
idx_depth_1 = find(depth <= Profundidad,1,'last');
idx_depth_2 = idx_depth_1 + 1;
depth_1 = depth(idx_depth_1);
depth_2 = depth(idx_depth_2);
dif_profs = double(depth_2 - depth_1);
incr_prof = double(Profundidad - depth_1);
if incr_prof == 0
     idx_depth_2 =  idx_depth_1;
end
u_p1_d1 = double(ncread(fileName,'U',[1, 1, idx_depth_2],[Inf, Inf, 1])');
u_p1_d1(u_p1_d1>1.2e+30) = NaN;
[lineax,lineay] = linea_isobata(u_p1_d1);
% Contadores auxiliares
ij          = 0; % contador de cada paso de tiempo
npar_acum   = 0;
aux_borrarx = 0;
aux_borrary = 0;

% Colores para las clases de petroleo
        c8 = [0.4940    0.1840    0.5560]; % morado
        c7 = 'm';                          % magenta
        c6 = 'b';                          % azul
        c5 = 'c';                          % cian
        c4 = [0.4660    0.7740    0.1880]; % verde
        c3 = 'y';                          % amarillo
        c2 = [0.9290    0.6940    0.1250]; % naranja
        c1 = 'r';                          % rojo

% Ciclo para dias
for  currDay = dia_inicio:dia_fin
    fprintf(['Dia juliano: ',num2str(currDay),'\n'])
    % Interpola los campos de velocidad a la Profundidad especificada
    nextDay = currDay+1;

    ra1=sprintf('%03d',currDay);
    ra2=sprintf('%03d',nextDay);

    fileName = [filePrefix,ra1,'_00_3z.nc'];
    fileName2 = [filePrefix,ra2,'_00_3z.nc'];

    % Reas the variables from dimensions [lat(1), lon(1), depth(idx_depth_2), time(1)], [All, All, onedepth, one time]
    u_p1_d1 = double(ncread(fileName,'U',[1, 1, idx_depth_1],[Inf, Inf, 1])');
    v_p1_d1 = double(ncread(fileName,'V',[1, 1, idx_depth_1],[Inf, Inf, 1])');
    u_p2_d1 = double(ncread(fileName,'U',[1, 1, idx_depth_2],[Inf, Inf, 1])');
    v_p2_d1 = double(ncread(fileName,'V',[1, 1, idx_depth_2],[Inf, Inf, 1])');
    u_p1_d2 = double(ncread(fileName2,'U',[1, 1, idx_depth_1],[Inf, Inf, 1])');
    v_p1_d2 = double(ncread(fileName2,'V',[1, 1, idx_depth_1],[Inf, Inf, 1])');
    u_p2_d2 = double(ncread(fileName2,'U',[1, 1, idx_depth_2],[Inf, Inf, 1])');
    v_p2_d2 = double(ncread(fileName2,'V',[1, 1, idx_depth_2],[Inf, Inf, 1])');

    % Assign Nan Values
    u_p1_d1(u_p1_d1>1.2e+30) = NaN;
    v_p1_d1(v_p1_d1>1.2e+30) = NaN;
    u_p1_d2(u_p1_d2>1.2e+30) = NaN;
    v_p1_d2(v_p1_d2>1.2e+30) = NaN;

    % Interoplates U and V to the current DEPTH level for day 1 and next day
    u_d1 = u_p1_d1 + incr_prof.*(u_p2_d1-u_p1_d1)./dif_profs;
    u_d2 = u_p1_d2 + incr_prof.*(u_p2_d2-u_p1_d2)./dif_profs;
    v_d1 = v_p1_d1 + incr_prof.*(v_p2_d1-v_p1_d1)./dif_profs;
    v_d2 = v_p1_d2 + incr_prof.*(v_p2_d2-v_p1_d2)./dif_profs;

    % Ciclo para cada paso de tiempo
    U = zeros([size(u_d1),5]);
    V = zeros([size(u_d1),5]);

    for t = 1:5;
        % Interpola los campos de velocidad al paso de tiempo "SeisHoras"
        U(:,:,t)  = u_d1 + (u_d2 - u_d1)*(t-1)/4; 
        V(:,:,t)  = v_d1 + (v_d2 - v_d1)*(t-1)/4; 
    end


    % Ciclo para cada paso de tiempo
    for SeisHoras = 1:4;
        ij = ij+1;

        if currDay <= ultimo_dia_derrame % Dias en los que hay derrame de petroleo

            idxSpillDates = find(FechasDerrame==currDay); % Get the index of the current date
            NumPart          = round(VDB(idxSpillDates)/400*fracc_VDB); % Computes the total number of particles to simulate (number of barrels/divided by 100)

            npar_acum = npar_acum + NumPart; % Total number of particles (accumulated)

            agregar = 0;

            % Because we add integer number of particles, we need to know how many
            % particles we won't add because of rounding errors. 
            if (sum(floor(NumPart*componentes)) < NumPart)
                agregar = NumPart-sum(floor(NumPart*componentes));
            elseif sum(floor(NumPart*componentes)) > NumPart
                agregar = -NumPart+sum(floor(NumPart*componentes));
            end

            for i = 1:8
                % Decide how many particles are we adding for each component
                m = floor(NumPart*componentes(i)+agregar*(i==8));
                % particulas que van a ser descargas
                XDerr = lon_derrame + randn(1,m).*0.02; % -88.3857
                YDerr = lat_derrame + randn(1,m).*0.02; % 28.7253
                VecFechasaux = zeros(1,m) + (currDay + (SeisHoras - 1)/4);
                % Updates the postion of particles in water for each component
                Xagua{i}     = [Xagua{i} XDerr];
                Yagua{i}     = [Yagua{i} YDerr];
                VecFechas{i} = [VecFechas{i} VecFechasaux];
            end
        end

        % Iterate over each oil component
        for i=1:8
            % Current particles positions
            XDerr_ant = Xagua{i};
            YDerr_ant = Yagua{i};
            XDerr1 = Xagua{i};
            YDerr1 = Yagua{i};
            NumPartAnt = length(XDerr_ant);

            % Verify we have at least one particle to process
            if NumPartAnt > 0
                %[XDerr1 , YDerr1] = advpartlbV2(LON,LAT,U(:,:,SeisHoras),V(:,:,SeisHoras), ...
                %                       U(:,:,SeisHoras+1),V(:,:,SeisHoras+1),XDerr1,YDerr1,1,6, BBOX);

                a = XDerr1;
                b = YDerr1;

                [XDerr1 , YDerr1] = advpartlbV2(LON,LAT,U(:,:,SeisHoras),V(:,:,SeisHoras), ...
                                       U(:,:,SeisHoras+1),V(:,:,SeisHoras+1),a,b,1,6);

                [teoz1, teoz2] = advpartlb(Lon,Lat,U,V,a,b,1,6);

                %err = sum(abs(XDerr1-teoz1)) + sum(abs(YDerr1-teoz2))

                DifX   = XDerr_ant - XDerr1;
                DifY   = YDerr_ant - YDerr1;
                % Busca particulas en agua (cuando no se movieron nada)
                EnAgua = find(DifX~=0 & DifY~=0);
                % Proceso de difusion
                if ~isempty(EnAgua)
                    XDerr1(EnAgua) = XDerr1(EnAgua) + randn(length(XDerr1(EnAgua)),1)'*0.01;
                    YDerr1(EnAgua) = YDerr1(EnAgua) + randn(length(YDerr1(EnAgua)),1)'*0.01;
                end
                %Busca particulas en tierra
                EnTierra   = find(DifX==0 & DifY==0);
                Xtierra{i} = [Xtierra{i} XDerr1(EnTierra)];
                Ytierra{i} = [Ytierra{i} YDerr1(EnTierra)];
                %Borramos las que estan en tierra
                XDerr1(EnTierra)       = [];
                YDerr1(EnTierra)       = [];
                VecFechas{i}(EnTierra) = [];
                Xagua{i}(EnTierra)     = [];
                Yagua{i}(EnTierra)     = [];
                % Eliminar particulas fuera del dominio [-98 -79 18.1 31]
                I_f = find(XDerr1 < BBOX(1) | YDerr1 < BBOX(2) | XDerr1 > BBOX(3) | YDerr1 > BBOX(4));
                if length(I_f) > 1
                    XDerr1(I_f)        = [];
                    YDerr1(I_f)        = [];
                    Xagua{i}(I_f)      = [];
                    Yagua{i}(I_f)      = [];
                    VecFechas{i}(I_f)  = [];
                    aux_borrarx        = aux_borrarx+length(I_f);
                end
                Xagua{i} = XDerr1;
                Yagua{i} = YDerr1;
            end
            % Conteo de particulas que pasan por una celda para cada clase de petroleo
            XDerr2 = Xagua{i};
            YDerr2 = Yagua{i};
            for jj = 1:length(XDerr2)
                J    = find(Lon<XDerr2(jj));
                IndJ =length(J);
                I    =find(Lat<YDerr2(jj));
                IndI =length(I);
                if IndI>0 && IndJ>0
                    Mat2(IndI,IndJ,i) = nansum([Mat2(IndI,IndJ,i);1]);
                end
            end
        end
        % Extraer informacion de particulas que estan en linea de costa
        x        = Lon(lineax);
        y        = Lat(lineay);
        contador = zeros(1,length(x));
        media    = zeros(1,length(x));
        % ciclo para encontrar puntos cercanos
        for i = 1:8
            for k = 1:length(Xtierra{i})
                [~ , h]         = min(sqrt((x-Xtierra{i}(k)).^2+(y-Ytierra{i}(k)).^2));
                Xtierra{i}(k) = x(h);
                Ytierra{i}(k) = y(h);
                contador(h)   = contador(h)+1;
            end
        end
        for i=2:length(contador)-2
            media(i) = 0.25*contador(i-1) + 0.5*contador(i)+0.25*contador(i+1);
        end
        figure(11)
        plot(media,'k') % media | contador
        % Biodegradacion
        if Decaimiento == 1;
            for i=1:8
                Ind2                   = rand(length(Xagua{i}),1);
                IndDesap               = find(Ind2 > t_degradacion(i));
                Xagua{i}(IndDesap)     = [];
                Yagua{i}(IndDesap)     = [];
                VecFechas{i}(IndDesap) = [];
                p_degradado{i}(ij)=length(IndDesap);
            end
        end
        % Decaimiento en linea de costa
        if Decaimiento == 1;
            for i=1:8
                Ind2     = rand(length(Xtierra{i}),1);
                IndDesap = find(Ind2 > t_degradacion(i));
                Xtierra{i}(IndDesap) = [];
                Ytierra{i}(IndDesap) = [];
                p_tierra{i}(ij) = length(IndDesap);
            end
        end

        % Grafica de particulas
        figure(9)
        mapa_graf = double(isnan(U(:,:,1))==0);
        pcolor(Lon,Lat,mapa_graf); shading flat
        colormap([0.4660    0.3    0.1880; 0 0 0])
        set(gca,'color',[.0 .0 .0]);
        set(gcf,'color','w')
        set(gcf,'InvertHardCopy','off');
        axis([-98 -79.5 18.1 31])
        hold on
        plot(Xagua{8},Yagua{8},'.','Color',c8,'MarkerSize',6)
        plot(Xagua{7},Yagua{7},'.','Color',c7,'MarkerSize',6)
        plot(Xagua{6},Yagua{6},'.','Color',c6,'MarkerSize',6)
        plot(Xagua{5},Yagua{5},'.','Color',c5,'MarkerSize',6)
        plot(Xagua{4},Yagua{4},'.','Color',c4,'MarkerSize',6)
        plot(Xagua{3},Yagua{3},'.','Color',c3,'MarkerSize',6)
        plot(Xagua{2},Yagua{2},'.','Color',c2,'MarkerSize',6)
        plot(Xagua{1},Yagua{1},'.','Color',c1,'MarkerSize',6)
        plot(cell2mat(Xtierra),cell2mat(Ytierra),'.w','MarkerSize',6)
        % Sitio del derrame
        plot(lon_derrame,lat_derrame,'s','MarkerSize',4,'MarkerEdgeColor','w',...
            'MarkerFaceColor','r')
        %title(['Dia ',num2str(currDay),' / paso de tiempo ',num2str(SeisHoras)])
        plot(mundo(:,1),mundo(:,2),'w')
        texto = {'C1 = rojo';'C2 = naranja';'C3 = amarillo';'C4 = verde';...
            'C5 = cian';'C6 = azul';'C7 = magenta';'C8 = morado'};
        text(-84,22.2,0,texto,'FontName','Monospaced','FontSize',10,...
            'BackgroundColor','w','EdgeColor','k','VerticalAlignment','top')
        drawnow
        %print ('-djpeg99','-r200',[Ruta_figuras,num2str(1000 + ij)]);
        %clf
        %%save(kf,'Xagua','Yagua','Xtierra','Ytierra');
        %%cantidad de petroleo en costa
        %hold on
        %figure(10)
        %oil_total = npar_acum;                                          if isempty(oil_total); oil_total = 0; end;
        %oil_water = length(cell2mat(Xagua));                            if isempty(oil_water); oil_water = 0; end;
        %oil_tierr = length(cell2mat(Xtierra));                          if isempty(oil_tierr); oil_tierr = 0; end;
        %oil_biode = sum(cell2mat(p_degradado))+sum(cell2mat(p_tierra)); if isempty(oil_biode); oil_biode = 0; end;
        %fuera_dom = aux_borrarx + aux_borrary;                          if isempty(fuera_dom); fuera_dom = 0; end;
        %subplot(1,2,1)
        %plot(1,oil_total,'+k')
        %hold on
        %plot(2,oil_water,'+b')
        %plot(3,oil_tierr,'+r')
        %plot(4,oil_biode,'+g')
        %plot(5,fuera_dom,'+y')
        %legend('Total','En agua','En costa','Biodegradado','Fuera dom')
        %legend('boxoff')
        %set(gca,'xticklabel',[])
        %subplot(1,2,2)
        %plot(1,oil_total,'+k')
        %hold on
        %plot(2,oil_water,'+b')
        %plot(3,oil_tierr,'+r')
        %plot(4,oil_biode,'+g')
        %plot(5,fuera_dom,'+y')
        %set(gca,'xticklabel',[])
        %set(gca, 'YScale', 'log')
        %balance= oil_total-(fuera_dom + oil_water + oil_tierr + oil_biode);
        %if balance ~= 0
        %    display(823), pause,  stop
        %end
    end%  fin ciclo SeisHoras
end %%fin ciclo currDay
%for j=1:8
%    figure(j)
%    pcolor(Lon,Lat,Mat2(:,:,j)), colorbar,caxis([0 500]),set(gca,'color',[.6 .6 .6]),colormap(barra_color)
%    hold on
%    plot(mundo(:,1),mundo(:,2),'k')
%    axis([-98 -79.5 18.1 31]); set(gcf,'color','w'),set(gcf,'InvertHardCopy','off'),shading flat
%    title({['C' num2str(j)]})
%    print ('-djpeg99','-r200',[Ruta_figuras,num2str(j)]);
%end
end
