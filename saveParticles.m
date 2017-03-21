load wind
[sx sy sz] = meshgrid(100,20:2:50,5);
%verts = stream3(x,y,z,u,v,w,sx,sy,sz);
%sl = streamline(verts);
%iverts = interpstreamspeed(x,y,z,u,v,w,verts,0.01);
p1 = rand(10,3);
p2 = rand(5,3);
iverts = {p1, p2}
set(gca,'SortMethod','childorder');
%streamparticles(iverts,15,...
%    'Animate',30,... % Number of times to animate the particle positions
%     'ParticleAlignment','on',...
%     'MarkerEdgeColor','none',...
%     'MarkerFaceColor','red',...
%     'Marker','o');

streamparticles(iverts,2,...
        'Animate',10, ... % Number of times to animate the particle positions
        'FrameRate', 3 ...
        );

