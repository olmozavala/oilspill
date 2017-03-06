function animacion3d(carpeta,dia_inicio,dia_fin,profundidades)
close all
fprintf('Haciendo la animacion tridimensional... \n')
colores = ['r','y','g','c','m'];
nombre_colores = {'Rojo    ','Amarillo','Verde   ','Cian    ','Magenta '};
outfile = [pwd,'/',carpeta,'/animacion_3d.gif'];
IMG = imread('golfo.jpg');
load Bati_Mex_GEBCO % Carga las variables Lat, Lon, ZZ
[XX] = find(Lon >=-98 & Lon <= -80);
[YY] = find(Lat >= 18 & Lat <= 31);
Z_GM = ZZ(YY(1):YY(end),XX(1):XX(end));
[I,J]=find(Z_GM>0);
for j=1:length(I)%207859
    Z_GM(I(j),J(j))=0;
end
%%%
surface(Lon(XX),Lat(YY),Z_GM,IMG,...
    'FaceColor','texturemap',...
    'EdgeColor','none',...
    'CDataMapping','direct')
hold on
plot3(-88.3857,28.7253,-1500:1:0,'.w','MarkerSize',5)
contour3(Lon(XX),Lat(YY),Z_GM,[0 0],'k','linewidth',2)
axis([-98 -80 18 31 -3950 0])
axis('off')
view(0,80)
title('2010 / Dia X / Paso de tiempo X','FontSize',12,'FontWeight','bold')
set(gca,'position',[0 -.17 1 1.099],'units','normalized')
% leyenda
colores_leg = length(profundidades);
if colores_leg > length(colores)
    colores_leg = length(colores);
end
texto = cell(colores_leg,1);
for i = 1:colores_leg
    leg_z = num2str(profundidades(i));
    texto{i} = [nombre_colores{i},' = ',leg_z,' m'];
end
texto = ['Azul     = 0 m';texto];
text(-86,21.1,0,texto,'FontName','Monospaced','FontSize',10,...
    'BackgroundColor','w','EdgeColor','k','VerticalAlignment','top')
l  = 0;
for hj = dia_inicio:dia_fin
    for SeisHoras = 1:4
        title(['2010 / Dia ',num2str(hj),' / Paso de tiempo ',num2str(SeisHoras)],...
            'FontSize',12,'FontWeight','bold')
        l=l+1;
        % superficie
        ruta=[pwd,'/',carpeta,'/','xy_superficie'];
        if l < 10
            ruta1=[ruta,'/sup_000',num2str(l)];
        elseif l >=10 && l<100
            ruta1=[ruta,'/sup_00',num2str(l)];
        elseif l >=100 && l<1000
            ruta1=[ruta,'/sup_0',num2str(l)];
        elseif l >=1000
            ruta1=[ruta,'/sup_',num2str(l)];
        end
        arut=['load ',ruta1,'.mat'];
        eval(arut); % Carga variables Xagua, Xtierra, Yagua, Ytierra
        Xagua = cell2mat(Xagua);
        Yagua = cell2mat(Yagua);
        Xtierra = cell2mat(Xtierra);
        Ytierra = cell2mat(Ytierra);
        hold on;
        Pa_sup = plot3(Xagua,Yagua,zeros(length(Xagua),1),'.b','MarkerSize',3);
        plot3(Xtierra,Ytierra,zeros(length(Xtierra),1),'.w','MarkerSize',3);
        % sub-superficie
        Pa = cell(1,length(profundidades));
        for Profs = 1:length(profundidades)
            prof_str = num2str(profundidades(Profs));
            ruta=[pwd,'/',carpeta,'/','xy_',prof_str];
            if l < 10
                ruta1=[ruta,'/',prof_str,'_m_000',num2str(l)];
            elseif l >=10 && l<100
                ruta1=[ruta,'/',prof_str,'_m_00',num2str(l)];
            elseif l >=100 && l<1000
                ruta1=[ruta,'/',prof_str,'_m_0',num2str(l)];
            elseif l >=1000
                ruta1=[ruta,'/',prof_str,'_m_',num2str(l)];
            end
            arut=['load ',ruta1,'.mat']; % Carga variables Xagua, Xtierra, Yagua, Ytierra
            eval(arut);
            Xagua   = cell2mat(Xagua);
            Yagua   = cell2mat(Yagua);
            Xtierra = cell2mat(Xtierra);
            Ytierra = cell2mat(Ytierra);
            if Profs <= length(colores)
                Color = colores(Profs);
            else
                Color = rand(1,3);
            end
            hold on
            Pa{Profs} = plot3(Xagua,Yagua,zeros(length(Xagua),1)-profundidades(Profs),...
                '.','Color',Color,'MarkerSize',3);
            plot3(Xtierra,Ytierra,zeros(length(Xtierra),1)-profundidades(Profs),...
                '.w','MarkerSize',3);
        end
        f = getframe(1);
        im=frame2im(f);
        [imind,cm]=rgb2ind(im,256);
        if l == 1
            imwrite(imind,cm,outfile,'gif','DelayTime',0,'loopcount',inf);
        else
            imwrite(imind,cm,outfile,'gif','DelayTime',0,'writemode','append');
        end
        delete(Pa_sup)
        for Profs = 1:length(profundidades)
            delete(Pa{Profs})
        end
    end
end
close all
end