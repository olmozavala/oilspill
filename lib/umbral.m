function [decaimiento]=umbral(dias)

horas = dias*24; % tiempo de decaimiento en horas 

%% Reduccion del (1/e)*100 % a los 62 dias
% reduccion del 95% a los 62 dias

% coeficientes de decaimiento

alfa_1h = 1/horas;  % decaimiento en horas

% calculo de umbral

%umbral_1d = 1-alfa_1d;   % decaimeinto en dias
umbral_1h = 1-alfa_1h*6;  % 

decaimiento = umbral_1h;
