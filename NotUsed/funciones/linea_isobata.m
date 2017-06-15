function [lineaX,lineaY] = linea_isobata(U)
Uiguales_col = zeros(size(U));
Uiguales_fil = zeros(size(U));
Unan = isnan(U);

[rows cols] = size(U);
% Encuentra las columnas contiguas cuyos valores son iguales
for columna = 1:cols-1
    Uiguales_col(:,columna) = Unan(:,columna) ~= Unan(:,columna+1);
end
% Encuentra los renglones contiguas cuyos valores son iguales
for fila = 1:rows-1
    Uiguales_fil(fila,:) = Unan(fila,:) ~= Unan(fila+1,:);
end
% Encuentra todas las celdas que tienen valores iguales en X o en Y
Uiguales = (Uiguales_col + Uiguales_fil) > 0;
% Indices con las posiciones con valores iguales
[lineay,lineax,~] = find(Uiguales == 1);
% Indice con la posicion en y mas chica
[~,punto_inicial] = min(lineay);
lineaX = [];
lineaY = [];
lineaX(1) = lineax(punto_inicial);
lineaY(1) = lineay(punto_inicial);
lineax(punto_inicial) = nan;
lineay(punto_inicial) = nan;
y_parar = min(lineay);
puntos_linea = 1;
continuar = 1;
while continuar == 1
    puntos_linea = puntos_linea + 1;
    diff_x = abs(lineax-lineaX(puntos_linea-1));
    diff_y = abs(lineay-lineaY(puntos_linea-1));
    sumas = diff_x + diff_y;
    [~,indice] = min(sumas);
    lineaX(puntos_linea) = lineax(indice);
    lineaY(puntos_linea) = lineay(indice);
    if lineay(indice) == y_parar
        continuar = 0;
    end
    lineax(indice) = nan;
    lineay(indice) = nan;
end
lineaY = lineaY + 1;
lineaX = lineaX + 1;
end
