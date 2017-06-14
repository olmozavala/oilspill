load('linea_costa_divpol.mat');
mexico = linea_costa;

%Tipo = ['.-b';'o-r';'*-g'];

figure
plot(mexico(:,1),mexico(:,2),'k','LineWidth',2); 

axis equal
axis([-110 -70 10 35])
axis([-100 -88 15 28])
