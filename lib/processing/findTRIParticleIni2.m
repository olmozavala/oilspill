function [ peleout ] = findTRIParticleIni2(xp,yp)
%   FINDTRIPARTICLEINI2     Find in what element a particle is located.
%   PELEOUT = FINDTRIPARTICLEINI2(XP,YP) takes in a particle with
%   coordinates XP,YP and searches the element PELEOUT where the particle
%   is located. If a particle is not found then PELEOUT returns 0

global VF;

%Using the VF.TR triangulation object, get the element where the particle
%with coordinates xp,yp is. (xp,yp can be column vectors).
peleout = pointLocation(VF.TR,xp,yp);

%Change NaN for 0 for consistency with the rest of the program. 
if sum(isnan(peleout))
    peleout(isnan(peleout)>0) = 0;
end

end

