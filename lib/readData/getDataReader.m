function [VF advFuntion]= getDataReader(modelType)
    % GETDATAREADER Is factory class to instanciate proper vector field reader.
    %     VF = getDataReader('hycom')
    switch modelType
        case 'hycom'
            VF  = VectorFields();
            advFuntion = @advectParticles;
        case 'adcirc'
            VF  = VectorFieldsADCIRC();
            VF  = VF.readLists();
            advFuntion = @advectParticlesADCIRC;
        otherwise
            error(strcat('Configuration for model: ', modelType, ' not found'));
    end
