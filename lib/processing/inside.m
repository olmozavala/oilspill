function [yesno] = inside(tria,xp,yp)
global VF

if (tria > 0)
    xt = VF.LON(VF.ELE(tria,:));
    yt = VF.LAT(VF.ELE(tria,:));
    in = inpolygon(xp,yp,xt,yt);
    % [in,on] = inpolygon(xp,yp,xt,yt)
    yesno = in > 0;
    clear in
else
    yesno = 0;
end

%     if (in > 0)
%         yesno = 1;
%     else
%         yesno = 0;
%     end

end