/* parte-3.mod */

param l, integer, >= 1;
param h, integer, >= 1;
param n, integer, >= 1;

param M, default 1000;

set CAJAS := 1..n;
set NIVELES := 1..h;
set FILAS := 1..l;
set COLUMNAS := 1..l;

param p {k in CAJAS}, integer, >= 1;
param w {k in CAJAS}, >= 0;
param gamma {k in CAJAS}, >= 0;

var x {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}, binary;
var P {s in NIVELES, i in FILAS, j in COLUMNAS}, >= 0;
var C {s in NIVELES, i in FILAS, j in COLUMNAS: i < l}, >= 0;

/* FUNCION OBJETIVO: coste medio real de las celdas efectivamente ocupadas */
minimize CosteMedio:
    (1/n) * sum {s in NIVELES, j in COLUMNAS, i in FILAS: i < l} C[s,i,j];

s.t. DefPrioridadPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    P[s,i,j] = sum {k in CAJAS} p[k] * x[k,s,i,j];

/* LINEALIZACION EXACTA DE C[s,i,j] */
/* 1. Si la celda (s,i,j) esta ocupada, C >= suma de prioridades delanteras */
s.t. DefCostePosicion_CotaInf {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    C[s,i,j] >= sum {i_prime in FILAS: i_prime > i} P[s,i_prime,j] - M * (1 - sum {k in CAJAS} x[k,s,i,j]);

/* 2. Si la celda (s,i,j) esta VACIA, C <= 0 (la fuerza a ser exactamente 0) */
s.t. DefCostePosicion_CotaSup1 {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    C[s,i,j] <= M * sum {k in CAJAS} x[k,s,i,j];

/* 3. Si la celda (s,i,j) esta ocupada, C <= suma de prioridades delanteras */
s.t. DefCostePosicion_CotaSup2 {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    C[s,i,j] <= sum {i_prime in FILAS: i_prime > i} P[s,i_prime,j];

/* RESTRICCIONES FISICAS Y DE ESTRUCTURA */
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