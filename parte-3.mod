
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

var x {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}, binary; /* x[k,s,i,j] = 1 si caja k en pos (s,i,j) */

/* FUNC OBJ: coste medio */
minimize CosteMedio:
    (1/n) * sum {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}
        (i-1) * p[k] * x[k,s,i,j];

/* RESTR: una pos por caja */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {s in NIVELES, i in FILAS, j in COLUMNAS} x[k,s,i,j] = 1;

/* RESTR: maximo una caja por pos */
s.t. MaxUnaCajaPorPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,s,i,j] <= 1;

/* RESTR: gravedad / soporte */
s.t. FloatingBox {s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k in CAJAS} x[k,s+1,i,j] <= sum {k in CAJAS} x[k,s,i,j];

/* RESTR: prioridades ordenadas con Big-M */
s.t. OrdenPrioridades {s in NIVELES, i in FILAS, j in COLUMNAS: i < l}:
    sum {k in CAJAS} p[k] * x[k,s,i+1,j]
    <= sum {k in CAJAS} p[k] * x[k,s,i,j] + M * (1 - sum {k in CAJAS} x[k,s,i,j]);

/* RESTR: capacidad de carga */
s.t. EmptyCapacity {s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k_sup in CAJAS, s_sup in NIVELES: s_sup > s} w[k_sup] * x[k_sup,s_sup,i,j]
    <= sum {k in CAJAS} gamma[k] * x[k,s,i,j];

end;