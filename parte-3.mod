/* p3: cajas INCOMPLETAS */

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
        /*  x[k,s,i,j] = 1 si caja k en pos (s,i,j) */
var P {s in NIVELES, i in FILAS, j in COLUMNAS}, >= 0;
        /* P[s,i,j] = prioridad en celda (s,i,j) */
var C {s in NIVELES, i in FILAS, j in COLUMNAS}, >= 0;
        /* C[s,i,j] = coste soportado por celda (s,i,j) */

/* FUNC OBJ: coste medio real de las cajas presentes */
minimize CosteMedio:
    (1/n) * sum {s in NIVELES, i in FILAS, j in COLUMNAS} C[s,i,j];

/* RESTR: definicion de la prioridad P */
s.t. DefPrioridadPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    P[s,i,j] = sum {k in CAJAS} p[k] * x[k,s,i,j];

/* RESTR: definicion del coste C solo si la posicion está OCUPADA (mediante Big-M) */
s.t. DefCostePosicion {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    C[s,i,j] >= sum {i_prime in FILAS: i_prime > i} P[s,i_prime,j] - M * (1 - sum {k in CAJAS} x[k,s,i,j]);

/* RESTR: una pos por caja */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {s in NIVELES, i in FILAS, j in COLUMNAS} x[k,s,i,j] = 1;

/* RESTR: maximo una caja por pos */
s.t. MaxUnaCajaPorPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,s,i,j] <= 1;

/* RESTR: contiguidad hacia la salida (huecos vacios al fondo) */
s.t. ContiguidadSalida {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    sum {k in CAJAS} x[k,s,i,j] <= sum {k in CAJAS} x[k,s,i+1,j];

/* RESTR: prioridades ordenadas con Big-M */
s.t. OrdenPrioridades {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    P[s,i+1,j] <= P[s,i,j] + M * (1 - sum {k in CAJAS} x[k,s,i,j]);

/* RESTR: gravedad / soporte */
s.t. FloatingBox {s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k in CAJAS} x[k,s+1,i,j] <= sum {k in CAJAS} x[k,s,i,j];

/* RESTR: capacidad de carga */
s.t. EmptyCapacity {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k_sup in CAJAS, s_sup in NIVELES: s_sup > s} w[k_sup] * x[k_sup,s_sup,i,j]
    <= sum {k in CAJAS} gamma[k] * x[k,s,i,j];

end;