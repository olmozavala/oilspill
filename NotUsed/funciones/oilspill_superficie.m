function [XDerr, YDerr] = oilspill_superficie(dia_inicio,dia_fin,ultimo_dia_derrame,...
    lon_derrame,lat_derrame,FechasDerrame,SurfaceOil,VBU,VE,VNW,...
    carpeta,t_degradacion,componentes_superficie,Decaimiento)
close all
fprintf('Haciendo el caso superficial... \n')
% Ruta de los archivos de viento y corrientes en superficie
Ruta = '/Dia_';
Ruta_particulas = [pwd,'/',carpeta,'/xy_superficie/'];
Ruta_figuras = [pwd,'/',carpeta,'/figuras_superficie/'];
mkdir(Ruta_particulas);
mkdir(Ruta_figuras);
% Inicializacion de vectores de posicion para cada clase de petroleo
Xagua       = cell(1,8); % Posicion de particulas en agua
Yagua       = Xagua;
Xtierra     = Xagua;     % Posicion de particulas en tierra
Ytierra     = Xagua;
VecFechas   = Xagua;     % Fechas de liberacion de particulas
p_quemado   = Xagua;     % Petroleo quemado
p_degradado = Xagua;     % Petroleo degradado
p_evaporado = Xagua;     % Petroleo evaporado
p_tierra    = Xagua;     % Petroleo en tierra
% Variable auxiliar para las imagenes de acumulativo
Mat2 = nan(385,541,8);
% Cargar variables guardadas previamente
barra_color = cell2mat(struct2cell(load('barra_color.mat')));
mundo = load('mundo.dat'); % Coordenadas lat,lon de una linea de costa global
% Generar isobata de la profundidad de simulacion
if dia_inicio < 10
    ra = ['00',num2str(dia_inicio)];
elseif dia_inicio < 100
    ra = ['0',num2str(dia_inicio)];
else
    ra = num2str(dia_inicio);
end
Arch    = [Ruta,ra,'_1.nc'];
Lon     = ncread(Arch,'Longitud');
Lat     = ncread(Arch,'Latitud');

[LON,LAT] = meshgrid(Lon,Lat);
BBOX = [min(Lon), min(Lat), max(Lon), max(Lat)]

u       = double(ncread(Arch,'U_Corriente'));
[lineax,lineay] = linea_isobata(u);
% Contadores auxiliares
auxp        = 0; % contador de cada paso de tiempo
npar_acum   = 0; % acumulado de petroleo
aux_borrarx = 0;
aux_borrary = 0;
t_agua       = zeros(length(lineax),1);
t_tierra     = t_agua;
t_total      = t_agua;
t_deg_tierra = t_agua;
t_quemado    = t_agua;
t_evaporado  = t_agua;
t_deg        = t_agua;
t_prueba     = t_agua;
cont_fig = 1000; % Contador inicial para las figuras
%  Ciclo para dias
for hj = dia_inicio: dia_fin
    fprintf(['Dia juliano: ',num2str(hj),'\n'])
    % Archivo netcdf con los campos de velocidad del dia hj
    if hj < 10
        ra=['00',num2str(hj)];
    elseif hj<100
        ra=['0',num2str(hj)];
    else
        ra=num2str(hj);
    end

    % Ciclo para cada paso de tiempo
    for SeisHoras = 1:4
        auxp     = auxp+1;
        cont_fig = cont_fig + 1;
        StrHora = num2str(SeisHoras);
        % Lectura del archivo netcdf
        Arch    = [Ruta,ra,'_',StrHora,'.nc'];
        Uw   = ncread(Arch,'U_Viento');
        Vw   = ncread(Arch,'V_Viento');
        Uc   = ncread(Arch,'U_Corriente');
        Vc   = ncread(Arch,'V_Corriente');
        Uw(isnan(Uc)) = nan;
        Vw(isnan(Vc)) = nan;
        % Efecto por viento
        [Uwr,Vwr] = rotangle(Uw,Vw); % Angulo de delfexion por Coriolis (Samuels 1982)
        % Si no consideramos efecto del viento descomentar las 2 lineas siguientes
        %Uwr        = Uw;
        %Vwr        = Vw;
        wind = 0.03;        % Contribucion del viento en la dispersion del petroleo
        U = Uc + Uwr*wind;
        V = Vc + Vwr*wind;
        %        NumPart    = 0;   % se divide entre 100 el número de barriles por dia y entre 4 porque es cada 6 hrs
        NumPartVBU = 0;   % Oil volume burned
        NumPartVE  = 0;   % VE Oil Volume evaporated or dissolved
        NumPartVNW = 0;   % VNW Oil volume skimmed
        if hj <= ultimo_dia_derrame % ultimo dia de derrame
            IndFechasDerrame = find(FechasDerrame==hj);
            NumPart = round(SurfaceOil(IndFechasDerrame)/400); %  Cantidad de particulas liberadas, se divide entre 100
            % Petroleo acumulado
            npar_acum = npar_acum+NumPart;
            % el número de barriles por dia y entre 4 porque es cada 6 hrs
            NumPartVBU = round(VBU(IndFechasDerrame)/400);
            NumPartVE  = round(VE(IndFechasDerrame)/400);
            NumPartVNW = round(VNW(IndFechasDerrame)/400);
            % Definicion de posiciones de particulas
            agregar = 0;
            if (sum(floor(NumPart*componentes_superficie)) < NumPart)         % 12 + 12 + 12 + 12 + 12 + 12 + 12 + 38 = 122; faltan 5 para 127
                agregar = NumPart-sum(floor(NumPart*componentes_superficie)); % agregar = 5
            elseif sum(floor(NumPart*componentes_superficie)) > NumPart       % si pasa lo contrario se restan
                agregar = -NumPart+sum(floor(NumPart*componentes_superficie));
            end
            for i = 1:8 % liberacion de particulas
                % las 5 que faltan se agregan a la ultima clase: 12 + 12 + 12 + 12 + 12 + 12 + 12 + 43 = 127
                m = floor(NumPart*componentes_superficie(i)+agregar*(i==8));
                n = 1;
                % particulas que van a ser descargas
                XDerr = lon_derrame + randn(n,m).*0.02; % -88.3857
                YDerr = lat_derrame + randn(n,m).*0.02; % 28.7253
                VecFechasaux = zeros(n,m) + (hj + (SeisHoras - 1)/4);
                Xagua{i} = [Xagua{i} XDerr];
                Yagua{i} = [Yagua{i} YDerr];
                VecFechas{i} = [VecFechas{i} VecFechasaux];
            end
        end  %fin hj <= ultimo_dia_derrame
        % Adveccion de particulas, identificacion de particulas en linea de costa
        for i=1:8
            % Posicion de la particula antes de ser advectada
            XDerr_ant = Xagua{i};
            YDerr_ant = Yagua{i};
            % Posicion de la particula despues de ser advectada
            XDerr1 = Xagua{i};
            YDerr1 = Yagua{i};
            % Numero de particulas antes de advectadas
            NumPartAnt = length(XDerr_ant);
            % Si hay particulas antes de la advecion
            if NumPartAnt > 0
                % Programa para ADVECTAR A LAS PARTICULAS
                %[XDerr1 , YDerr1] = advpartlb(Lon,Lat, U,V,XDerr1,YDerr1,1,6);

                [XDerr1 , YDerr1] = advpartlbV2(LON,LAT,U',V', U',V',XDerr1,YDerr1,1,6);
                DifX = XDerr_ant - XDerr1;
                DifY = YDerr_ant - YDerr1;
                % Encuentra indices de particulas que no han llegado a tierra
                EnAgua = find(DifX~=0 | DifY~=0);
                % Efecto por difusion para particulas que se encuentran en agua
                if ~isempty(EnAgua)
                    XDerr1(EnAgua) = XDerr1(EnAgua) + randn(length(XDerr1(EnAgua)),1)'*0.01;
                    YDerr1(EnAgua) = YDerr1(EnAgua) + randn(length(YDerr1(EnAgua)),1)'*0.01;
                end
                % Buscamos particulas en tierra
                EnTierra   = find(DifX==0 & DifY==0);
                % Actualizamos particulas que se encuentran en Tierra
                Xtierra{i} = [Xtierra{i} XDerr1(EnTierra)];
                Ytierra{i} = [Ytierra{i} YDerr1(EnTierra)];
                % Borramos las que estan en tierra de las particulas advectadas
                XDerr1(EnTierra)       = [];
                YDerr1(EnTierra)       = [];
                VecFechas{i}(EnTierra) = [];
                % Borramos particulas en tierra
                Xagua{i}(EnTierra)     = [];
                Yagua{i}(EnTierra)     = [];
                % Eliminar particulas fuera del dominio [-98 -79 18.1 31]
                I_f                = find(XDerr1 >-79 );
                if length(I_f)>1
                    XDerr1(I_f)        = [];
                    YDerr1(I_f)        = [];
                    Xagua{i}(I_f)      = [];
                    Yagua{i}(I_f)      = [];
                    VecFechas{i}(I_f)  = [];
                    aux_borrarx        = aux_borrarx+length(I_f); % Conteo de particulas que salen del dominio
                end
                % Eliminar particulas fuera del dominio [-98 -79 18.1 31]
                I_f                = find(YDerr1 >31 );
                if length(I_f)>1
                    XDerr1(I_f)        = [];
                    YDerr1(I_f)        = [];
                    Xagua{i}(I_f)      = [];
                    Yagua{i}(I_f)      = [];
                    VecFechas{i}(I_f)    = [];
                    aux_borrary        = aux_borrary+length(I_f);
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
            end % pcolor(Mat2(:,:,1)); shading flat; colorbar
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
        % Evaporacion
        if Decaimiento.evaporacion == 1
            %p_evaporado = 0;
            for i=1:8   % No se evaporan todas las clases a la misma tasa
                %IndPart=[]; Ind2=[];
                Ind =[];
                % elimina partículas por evaporación
                IndPart = find(VecFechas{i}==(hj + (SeisHoras-1)/4));
                if IndPart >1
                    Fraccion = NumPartVE/length(IndPart);
                    Ind2     = rand(length(IndPart),1);
                    if Fraccion >= .35
                        Fraccion = .35;
                    end
                    for ik = 1:length(Ind2)
                        if Ind2(ik) < Fraccion
                            Xagua{i}(ik) = NaN;
                        end
                    end
                    %p_evaporado=length(Ind);
                    Ind               = find(isnan(Xagua{i})==1);
                    Xagua{i}(Ind)     = [];
                    Yagua{i}(Ind)     = [];
                    VecFechas{i}(Ind) = [];
                end
                p_evaporado{i}(auxp) = length(Ind) ;
            end
        end
        % Biodegradacion
        if Decaimiento.biodegradacion == 1;
            for i=1:8
                Ind2                   = rand(length(Xagua{i}),1);
                IndDesap               = find(Ind2 > t_degradacion(i));
                Xagua{i}(IndDesap)     = [];
                Yagua{i}(IndDesap)     = [];
                VecFechas{i}(IndDesap) = [];
                % XDerr_cont1(IndDesap)=[];
                %p_quemado=length(Ind);
                p_degradado{i}(auxp)=length(IndDesap);
            end
        end
        % Quema y recoleccion
        if Decaimiento.artificial == 1
            for i=1:8
                Ind     = [];   % -88.3857                  % 28.7253
                Dist    = sqrt((lon_derrame-Xagua{i}).^2 + (lat_derrame-Yagua{i}).^2);
                IndPart = find(Dist < 3);
                if IndPart > 1
                    Fraccion = 0.33*(NumPartVBU+NumPartVNW)/length(IndPart);
                    Ind2     = rand(length(IndPart),1);
                    if Fraccion >= .9
                        Fraccion = .9;
                    end
                    for ik = 1:length(Ind2)
                        if Ind2(ik) < Fraccion
                            Xagua{i}(ik) = NaN;
                        end
                    end
                    Ind = find(isnan(Xagua{i})==1);
                    Xagua{i}(Ind)     = [];
                    Yagua{i}(Ind)     = [];
                    VecFechas{i}(Ind) = [];
                end
                p_quemado{i}(auxp)=length(Ind);
            end
        end
        % Decaimiento en linea de costa
        if Decaimiento.biodegradacion == 1;
            for i=1:8
                Ind2     = rand(length(Xtierra{i}),1);
                IndDesap = find(Ind2 > t_degradacion(i));
                Xtierra{i}(IndDesap) = [];
                Ytierra{i}(IndDesap) = [];
                %VecFechas{i}(IndDesap) = []; %#ok<SAGROW>
                % XDerr_cont1(IndDesap)=[];
                p_tierra{i}(auxp) = length(IndDesap);
            end
        end
        % Colores para las clases de petroleo
        c8 = [0.4940    0.1840    0.5560]; % morado
        c7 = 'm';                          % magenta
        c6 = 'b';                          % azul
        c5 = 'c';                          % cian
        c4 = [0.4660    0.7740    0.1880]; % verde
        c3 = 'y';                          % amarillo
        c2 = [0.9290    0.6940    0.1250]; % naranja
        c1 = 'r';                          % rojo
        % Grafica de particulas
        figure(9)
        clf
        plot(Xagua{8},Yagua{8},'.','Color',c8,'MarkerSize',6)
        hold on
        plot(Xagua{7},Yagua{7},'.','Color',c7,'MarkerSize',6)
        plot(Xagua{6},Yagua{6},'.','Color',c6,'MarkerSize',6)
        plot(Xagua{5},Yagua{5},'.','Color',c5,'MarkerSize',6)
        plot(Xagua{4},Yagua{4},'.','Color',c4,'MarkerSize',6)
        plot(Xagua{3},Yagua{3},'.','Color',c3,'MarkerSize',6)
        plot(Xagua{2},Yagua{2},'.','Color',c2,'MarkerSize',6)
        plot(Xagua{1},Yagua{1},'.','Color',c1,'MarkerSize',6)
        plot(cell2mat(Xtierra),cell2mat(Ytierra),'.w','MarkerSize',6)
        
        plot(lon_derrame,lat_derrame,'s','MarkerSize',4,'MarkerEdgeColor','w',...
            'MarkerFaceColor','r')
        %    caxis([15 30]);
        set(gca,'color',[.0 .0 .0]);
        set(gcf,'color','w')
        set(gcf,'InvertHardCopy','off');
        title(['Dia ',num2str(hj),' / paso de tiempo ',num2str(SeisHoras)])
        axis([-98 -79.5 18.1 31])
        plot(mundo(:,1),mundo(:,2),'w')
        texto = {'C1 = rojo';'C2 = naranja';'C3 = amarillo';'C4 = verde';...
            'C5 = cian';'C6 = azul';'C7 = magenta';'C8 = morado'};
        %text(-84,22.2,0,texto,'FontName','Monospaced','FontSize',10,...
        %    'BackgroundColor','w','EdgeColor','k','VerticalAlignment','top')
        %print ('-djpeg99','-r200',[Ruta_figuras,num2str(cont_fig)]);
        if auxp < 10
            kf=[Ruta_particulas,'sup_000',num2str(auxp)];
        elseif auxp >=10 && auxp<100
            kf=[Ruta_particulas,'sup_00',num2str(auxp)];
        elseif auxp >=100 && auxp<1000
            kf=[Ruta_particulas,'sup_0',num2str(auxp)];
        elseif auxp >=1000
            kf=[Ruta_particulas,'sup_',num2str(auxp)];
        end
        % Guardar posiciones particulas en carpeta
        %save(kf,'Xagua','Yagua','Xtierra','Ytierra');
        hold on
        t_agua(auxp)       = length(cell2mat(Xagua));
        t_tierra(auxp)     = length(cell2mat(Xtierra));
        t_total(auxp)      = npar_acum;
        t_deg_tierra(auxp) = sum(cellfun(@sum, p_tierra));
        t_quemado(auxp)    = sum(cellfun(@sum, p_quemado));
        t_evaporado(auxp)  = sum(cellfun(@sum, p_evaporado));
        t_deg(auxp)        = sum(cellfun(@sum, p_degradado));
        t_prueba(auxp)     = t_agua(auxp)+t_tierra(auxp)+t_deg_tierra(auxp)+...
            t_quemado(auxp)+t_evaporado(auxp)+t_deg(auxp);
        figure(10)
        oil_total = npar_acum;                                          if isempty(oil_total); oil_total = 0; end;
        oil_water = length(cell2mat(Xagua));                            if isempty(oil_water); oil_water = 0; end;
        oil_tierr = length(cell2mat(Xtierra));                          if isempty(oil_tierr); oil_tierr = 0; end;
        oil_evapo = sum(cell2mat(p_evaporado));                         if isempty(oil_evapo); oil_evapo = 0; end;
        oil_biode = sum(cell2mat(p_degradado))+sum(cell2mat(p_tierra)); if isempty(oil_biode); oil_biode = 0; end;
        oil_remov = sum(cell2mat(p_quemado));                           if isempty(oil_remov); oil_remov = 0; end;
        fuera_dom = aux_borrarx + aux_borrary;                          if isempty(fuera_dom); fuera_dom = 0; end;
        subplot(1,2,1)
        plot(1,oil_total,'+k')
        hold on
        plot(2,oil_water,'+b')
        plot(3,oil_tierr,'+r')
        plot(4,oil_evapo,'+c')
        plot(5,oil_biode,'+g')
        plot(6,oil_remov,'+m')
        plot(7,fuera_dom,'+y')
        legend('Total','En agua','En costa','Evaporado','Biodegradado',...
            'Remocion A','Fuera dom')
        legend('boxoff')
        set(gca,'xticklabel',[])
        subplot(1,2,2)
        plot(1,oil_total,'+k')
        hold on
        plot(2,oil_water,'+b')
        plot(3,oil_tierr,'+r')
        plot(4,oil_evapo,'+c')
        plot(5,oil_biode,'+g')
        plot(6,oil_remov,'+m')
        plot(7,fuera_dom,'+y')
        set(gca,'xticklabel',[])
        set(gca, 'YScale', 'log')
        %         plot(t_total ,'LineWidth',2)
        %         hold on
        %         plot(t_agua  , 'LineWidth',2)
        %         plot(t_tierra, 'LineWidth',2)
        %         plot(t_deg_tierra, 'LineWidth',2)
        %         plot(t_quemado, 'LineWidth',2)
        %         plot(t_evaporado, 'LineWidth',2)
        %         plot(t_deg, 'LineWidth',2)
        %        plot(t_prueba, 'LineWidth',2,'r')
        %         legend('P total','P agua','P tierra','P deg_tierra',...
        %             'P quemado','P evaporado','P deg','P prueba')
        %        pause(0.1)
        % Balance de masa
        balance= oil_total-(fuera_dom + oil_water + oil_tierr + oil_remov +...
            oil_evapo + oil_biode);
        if balance ~= 0
            display(823), pause,  stop
        end
    end % fin seis horas
end % fin hj
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
