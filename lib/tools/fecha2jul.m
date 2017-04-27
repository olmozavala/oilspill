function[diajuliano] = fecha2jul(Mes,Dia,Anio)  
% funcion fecha2juliano
% [diajuliano] = fecha2jul(Mes,Dia,Anio)

% Convierte una fecha en dia juliano
% Los valores de Mes, Dia y Anio deben ser numericos.
NumMes = [ 0 31 59 90 120 151 181 212 243 273 304 334];
NumMesB= [ 0 31 60 91 121 152 182 213 244 274 305 335]; % Anio Bisiesto

if (mod(Anio,4) == 0 & mod(Anio,100) ~= 0) | mod(Anio,400) == 0
    DiaMeses = NumMesB;
else
    DiaMeses = NumMes;
end

diajuliano = DiaMeses(Mes) + Dia;


