/* parte3: cajas INCOMPLETAS*/

param l, integer, >= 1;
param h, integer, >= 1;
param n, integer, >= 1;

param M, default 100000;

set CAJAS := 1..n;
set NIVELES := 1..h;
set FILAS := 1..l;
set COLUMNAS := 1..l;

param p {k in CAJAS}, integer, >= 1;
param w {k in CAJAS}, >= 0;
param gamma {k in CAJAS}, >= 0;

var x {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}, binary;
var P {s in NIVELES, i in FILAS, j in COLUMNAS}, >= 0;

/* Funcion Objetivo pura de la practica */
minimize CosteMedio:
    (1/n) * sum {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}
        sum {i_prime in FILAS: i_prime > i} P[s,i_prime,j];

s.t. DefPrioridadPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    P[s,i,j] = sum {k in CAJAS} p[k] * x[k,s,i,j];

s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {s in NIVELES, i in FILAS, j in COLUMNAS} x[k,s,i,j] = 1;

s.t. MaxUnaCajaPorPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,s,i,j] <= 1;

s.t. ContiguidadSalida {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    sum {k in CAJAS} x[k,s,i,j] <= sum {k in CAJAS} x[k,s,i+1,j];

s.t. OrdenPrioridades {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    P[s,i+1,j] <= P[s,i,j] + M * (1 - sum {k in CAJAS} x[k,s,i,j]);

s.t. FloatingBox {s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k in CAJAS} x[k,s+1,i,j] <= sum {k in CAJAS} x[k,s,i,j];

s.t. EmptyCapacity {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k_sup in CAJAS, s_sup in NIVELES: s_sup > s} w[k_sup] * x[k_sup,s_sup,i,j]
    <= sum {k in CAJAS} gamma[k] * x[k,s,i,j];

end;