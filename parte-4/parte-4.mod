
/* p4: pallets INCOMPLETOS */

param l, integer, >= 1;
param h, integer, >= 1;
param n, integer, >= 1;
param precio, >= 0;
param M, default 100000;
set CAJAS := 1..n;
set PALLETS := 1..n;
set NIVELES := 1..h;
set FILAS := 1..l;
set COLUMNAS := 1..l;
param p {k in CAJAS}, integer, >= 1;
param w {k in CAJAS}, >= 0;
param gamma {k in CAJAS}, >= 0;

/* var de decision */
var x {k in CAJAS, b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS}, binary;
var P {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS}, >= 0;
var C {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS}, >= 0;
var usar {b in PALLETS}, binary;

/* FUNC OBJ: coste total */
minimize CosteTotal:
    sum {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS} C[b,s,i,j] + precio * sum {b in PALLETS} usar[b];

/* RESTR: prioridad */
s.t. DefPrioridadPosicion
    {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS}:
    P[b,s,i,j] = sum {k in CAJAS} p[k] * x[k,b,s,i,j];

/* RESTR: coste (p3) */
s.t. DefCostePosicion
    {b in PALLETS, s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    C[b,s,i,j] >= sum {i_prime in FILAS: i_prime > i} P[b,s,i_prime,j] - M * (1 - sum {k in CAJAS} x[k,b,s,i,j]);

/* RESTR: 1 pos por caja */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS} x[k,b,s,i,j] = 1;

/* RESTR: max 1 caja por pos */
s.t. MaxUnaCajaPorPosicion
    {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,b,s,i,j] <= 1;

/* RESTR: activar pallets */
s.t. ActivarPallet {b in PALLETS}:
    sum {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS} x[k,b,s,i,j] <= n * usar[b];

s.t. NoActivarVacio {b in PALLETS}:
    usar[b] <= sum {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS} x[k,b,s,i,j];

/* RESTR: contiguidad */
s.t. ContiguidadSalida
    {b in PALLETS, s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    sum {k in CAJAS} x[k,b,s,i,j] <= sum {k in CAJAS} x[k,b,s,i+1,j];

/* RESTR: prioridades ordenadas */
s.t. OrdenPrioridades
    {b in PALLETS, s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    P[b,s,i+1,j] <= P[b,s,i,j] + M * (1 - sum {k in CAJAS} x[k,b,s,i,j]);

/* RESTR: NO cajas flotando */
s.t. FloatingBox
    {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k in CAJAS} x[k,b,s+1,i,j] <= sum {k in CAJAS} x[k,b,s,i,j];

/* RESTR: capacidad de carga */
s.t. EmptyCapacity
    {b in PALLETS, s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k_sup in CAJAS, s_sup in NIVELES: s_sup > s} w[k_sup] * x[k_sup,b,s_sup,i,j] <= sum {k in CAJAS} gamma[k] * x[k,b,s,i,j];

end;
