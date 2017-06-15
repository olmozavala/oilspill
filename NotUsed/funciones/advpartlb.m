function[XN,YN] = advpartlb(X0,Y0,U,V,X1,Y1,N,DT)
% ADVPARTL FUNCTION para graficar partículas
% function[XN,YN] = advpartl(X0,Y0,U,V,X1,Y1,N,DT,RH)
% usa un Runge Kutta orden 2
%
% X0 es el vector o matriz de longitudes (en grados)
% Y0 el el vector o matriz de latitudes (en grados)
% U es una matriz con la componente U de la velocidad
% V es una matriz con la componente V de la velocidad
% X1 es un vector o matriz con las longitudes de las partículas
% Y1 es un vector o matriz con las latitudes de las partículas
% N es el número de segmentos
% DT es el incremento de tiempo en horas
% RH es la resolución horizontal de la  malla. Espera una malla uniforme (DX=cte, DY=cte)
% en latitud y longitud
%
% Si la partícula se sale del dominio se queda en la frontera
%
% Elborada por Jorge Zavala

% (lonGoM,latGoM, Up,Vp,XDerr2a,YDerr2a,24,1,0.05)
% (X0,Y0,U,V,X1,Y1,N,DT,RH)
% X0 = lonGoM;
% Y0 = latGoM;
% U = Up;
% V = Vp;
% X1 = XDerr2a;
% Y1 = YDerr2a;
% N = 24;
% DT = 1;
% RH = 0.05;

%,U,V,X1,Y1,N,DT,RH)

DeltaT = DT*3600;
% alfa=pi/12;    % es el �ngulo entre el vector y cada punta de flecha
% TPunta=.13;
%VecColor=C;
%VecColor='w';
%VecColor=[.7 .7 .7];
% GruesoLinea=.3;
R=6371e+03;                 % Radio medio de la tierra (Gill)
RH = X0(2)-X0(1);
DeltaTeta=(2*pi/360)*RH;
%DelY=R*DeltaTeta/(R*(2*pi/360));


% DeltaTeta=(2*pi/360);
DelY=R*DeltaTeta;

for ii=1:length(Y0)
    iLat = Y0(ii);
    DelX(ii)=R*DeltaTeta*cos((iLat)*pi/180);
end

[Sx Sy]=size(X0);
if Sx==1 || Sy==1
    [X,Y] = meshgrid(X0,Y0);
else
    X=X0;
    Y=Y0;
end
[Sx Sy]=size(X);

Sx1 =size(X1);

XX1=X1;
YY1=Y1;

XN=XX1;
YN=YY1;

DeltaX = X(1,2) - X(1,1);  % supone matriz uniforme
DeltaY = Y(2,1) - Y(1,1);

%hold on

[Sx1 Sy1]=size(XX1);
for ii=1:Sx1   % realiza los calculos para cada vector
    for jj=1:Sy1
        MX=[];
        MY=[];
        %ii
        %jj
        MX(1) = XX1(ii,jj); % coordenadas de las partículas
        MY(1) = YY1(ii,jj);
        k=1;
        HayDatos=0;
        for g=1:N       % calcula para cada segmento del vector
            %g
            J = 1+floor((MX(k) - X(1,1))/DeltaX);
            %I = 1+floor((MY(k) - Y(1,1))/DeltaY);
         IJK = find(Y0 < MY(k));
         I = length(IJK);

            % Verifica que esten dentro 
            if I >= 1 && I < Sx && J >=1 && J < Sy
                if isnan(U(I,J))~=1 && isnan(U(I+1,J))~=1 ...
                        && isnan(U(I,J+1))~=1 && isnan(U(I+1,J+1))~=1
                    HayDatos=1;
                    % Interpolate U and V
                    IncX = (MX(k) - X(I,J))/DeltaX;
                    IncY = (MY(k) - Y(I,J))/DeltaY;
                    Ua = U(I,J) + (U(I,J+1) - U(I,J)) * IncX;
                    Ub = U(I+1,J) + (U(I+1,J+1) - U(I+1,J)) * IncX;
                    MU(k) = Ua + (Ub - Ua) * IncY;
                    Va = V(I,J) + (V(I,J+1) - V(I,J)) * IncX;
                    Vb = V(I+1,J) + (V(I+1,J+1) - V(I+1,J)) * IncX;
                    MV(k) = Va + (Vb - Va) * IncY;
                    %MX(k+1) = MX(k) + MU(k)*DeltaT;
                    %MY(k+1) = MY(k) + MV(k)*DeltaT;
                    MXInt = MX(k) + MU(k)*DeltaT*cos(MY(k)*pi/180)*(180/(pi*R))/2;  %/(2*R*DelX(I)); % se ubica a delta/2
                    MYInt = MY(k) + MV(k)*DeltaT*(180/(pi*R))/2;  %/(2*R*DelY); % se ubica a delta/2
                    JInt = 1+floor((MXInt - X(1,1))/DeltaX);
                    IInt = 1+floor((MYInt - Y(1,1))/DeltaY);

                    % Checa si se salio del domino
                    if IInt >= 1 && IInt < Sx && JInt >=1 && JInt < Sy
                        % Checa si sigo en agua
                        if isnan(U(IInt,JInt))~=1 && isnan(U(IInt+1,JInt))~=1 ...
                                && isnan(U(IInt,JInt+1))~=1 && isnan(U(IInt+1,JInt+1))~=1
                            IncX = (MXInt - X(I,J))/DeltaX;
                            IncY = (MYInt - Y(I,J))/DeltaY;
                            Ua = U(I,J) + (U(I,J+1) - U(I,J)) * IncX;
                            Ub = U(I+1,J) + (U(I+1,J+1) - U(I+1,J)) * IncX;
                            MU(k) = Ua + (Ub - Ua) * IncY;
                            Va = V(I,J) + (V(I,J+1) - V(I,J)) * IncX;
                            Vb = V(I+1,J) + (V(I+1,J+1) - V(I+1,J)) * IncX;
                            MV(k) = Va + (Vb - Va) * IncY;
                            MX(k+1) = MX(k) + MU(k)*DeltaT*cos(MY(k)*pi/180)*(180/(pi*R));   %*DelX(I) DelX(ii)=R*DeltaTeta*cos((iLat)*pi/180);
                            MY(k+1) = MY(k) + MV(k)*DeltaT*(180/(pi*R));  %*DelY
                            k=k+1;
                        end
                    else
                        MX(k+1) = NaN;
                        MY(k+1) = NaN;
                    end
                end
            end
        end
        %      plot(MX,MY,'k');
        %      MX
        %       plot(MX(k+1),MY(k+1),'o','LineWidth',GruesoLinea);
        %ya=1
        %pause
        %      hold on
        if k >= N && HayDatos==1
            %        u(1)=MX(end-1);
            %        v(1)=MY(end-1);
            %        u(2)=MX(end);
            %        v(2)=MY(end);
            %        w=u+v*j;
            %        teta2=atan2(v(2)-v(1),u(2)-u(1));
            %        w2=TPunta*exp(j*(teta2+alfa));
            %        w3=TPunta*exp(j*(teta2-alfa));
            %        w2b(1)=w(2);
            %        w3b(1)=w(2);
            %        w2b(2)=w(2)-w2;
            %        w3b(2)=w(2)-w3;
            %        %plot(w);
            %        plot(w2b,'color',VecColor,'LineWidth',GruesoLinea);
            %        plot(w3b,'color',VecColor,'LineWidth',GruesoLinea) %axis equal
            %        XN(ii)=MX(k);
            %        YN(ii)=MY(k);
            %       clear w w2 w3 w2b w3b
        end
        %ya=MX(k)
        XN(jj)=MX(k);
        YN(jj)=MY(k);
    end
end
%XN
