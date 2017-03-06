function particles = initParticles(particles, spillData, modelConfig, currDay, currHour)
        barrelsPerParticle = barrelsPerParticle % How many barrels does a particle represent
        
        currDateIdx = find(spillData.dates == currHour);
        NumPart = round(spillData.barrels(currDateIdx)/barrelsPerParticle); %  Cantidad de particulas liberadas, se divide entre 100

        % el número de barriles por dia y entre 4 porque es cada 6 hrs
        NumPartVE  = round(VE(IndFechasDerrame)/barrelsPerParticle);
        NumPartVNW = round(VNW(IndFechasDerrame)/barrelsPerParticle);

        % Adding surface particles
        % Adding subsurface particles
        numPartToAdd = 0;
        if (sum(floor(NumPart*componentes_superficie)) < NumPart)         % 12 + 12 + 12 + 12 + 12 + 12 + 12 + 38 = 122; faltan 5 para 127
            numPartToAdd = NumPart-sum(floor(NumPart*componentes_superficie)); % numPartToAdd = 5
        elseif sum(floor(NumPart*componentes_superficie)) > NumPart       % si pasa lo contrario se restan
            numPartToAdd = -NumPart+sum(floor(NumPart*componentes_superficie));
        end
        for i = 1:8 % liberacion de particulas
            % las 5 que faltan se agregan a la ultima clase: 12 + 12 + 12 + 12 + 12 + 12 + 12 + 43 = 127
            m = floor(NumPart*componentes_superficie(i)+numPartToAdd*(i==8));
            n = 1;
            % particulas que van a ser descargas
            XDerr = lon_derrame + randn(n,m).*0.02; % -88.3857
            YDerr = lat_derrame + randn(n,m).*0.02; % 28.7253
            VecFechasaux = zeros(n,m) + (hj + (SeisHoras - 1)/4);
            Xagua{i} = [Xagua{i} XDerr];
            Yagua{i} = [Yagua{i} YDerr];
            VecFechas{i} = [VecFechas{i} VecFechasaux];
        end


