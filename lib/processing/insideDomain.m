function [yesno,xout,yout] = insideDomain(xp,yp,xn,yn,VF)
%   INSIDEDOMAIN    Find if particle is inside the domain. 
%   [YESNO,XOUT,YOUT] = INSIDEDOMAIN(PELEIN,XP,YP,YN) takes in the particle with coordinates XP,YP that moved to the new
%   coordinates XN,YN and determines if the new coordinate is inside or
%   outside the ocean domain. If the particle is outside the ocean domain
%   then the particle coordinates XOUT YOUT remain unchaged, if the particle remains
%   inside the ocean domain after moving then XOUT YOUT reflect the new
%   positions. YESNO is an index indicating if the particle was allowed to
%   move or not. 
%   
%   This function uses function "findTRIParticleIni2" developed by team
%   FVCOM/ADCIRC, and the matlab built-in function "inpolygon".

xout = xn;
yout = yn;
yesno = xp*0;
cantP = length(xp);


%in = inpolygon(xn,yn,VF.CostaX,VF.CostaY);
%
%inIdx = find(in);
%outIdx = find(~in);
%
%xout(outIdx) = xp(outIdx);
%yout(outIdx) = yp(outIdx);
%
%peleout = pointLocation(VF.TR,xp(inIdx)',yp(inIdx)');
%
%outIdx = find(~peleout);
%
%xout(outIdx) = xp(outIdx);
%yout(outIdx) = yp(outIdx);
%
%Change NaN for 0 for consistency with the rest of the program. 

for ii = 1:cantP
    in = inpolygon(xn(ii),yn(ii),VF.CostaX,VF.CostaY);
    % [in,on] = inpolygon(xp,yp,xt,yt)
    if in == 0
        xout(ii) = xp(ii);
        yout(ii) = yp(ii);
    else
        pele = findTRIParticleIni2(xn(ii),yn(ii),VF);
%         if (pele == 0)
%             %Particle is INSIDE the domain, find the element.
%             pele = findTRIParticleIni2(xn(ii),yn(ii));
%         end
        if (pele == 0)
            xout(ii) = xp(ii);
            yout(ii) = yp(ii);
        else
            %Get velocity of the nodes of element.
            ut = find(VF.U(VF.ELE(pele,:))==0.0);
            vt = find(VF.V(VF.ELE(pele,:))==0.0);
            ut2 = find(VF.UT2(VF.ELE(pele,:))==0.0);
            vt2 = find(VF.VT2(VF.ELE(pele,:))==0.0);
            if ((sum(ut) > 0) || (sum(vt) > 0)) && ((sum(ut2) > 0) || (sum(vt2) > 0))
                xout(ii) = xp(ii);
                yout(ii) = yp(ii);
            end
        end
    end
    yesno(ii) = in > 0;
    clear in
    
end

end
