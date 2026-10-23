
/* p1: cajas CON PRIORIDAD */

param l, integer, >= 1;
param n, integer, >= 1;
set CAJAS := 1..n;
set FILAS := 1..l;
set COLUMNAS := 1..l;
param p {k in CAJAS}, integer, >= 1;

var x {k in CAJAS, i in FILAS, j in COLUMNAS}, binary; /* x[k,i,j] = 1 si caja k en pos (i,j) */

/* FUNC OBJ: coste medio */
minimize CosteMedio:
    (1/n) * sum {k in CAJAS, i in FILAS, j in COLUMNAS}
        (i-1) * p[k] * x[k,i,j];

/* RESTR: una pos por caja */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {i in FILAS, j in COLUMNAS} x[k,i,j] = 1;

/* RESTR: una caja por pos */
s.t. UnaCajaPorPosicion {i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,i,j] = 1;

/* RESTR: prioridades ordenadas */
s.t. OrdenPrioridades {i in FILAS, j in COLUMNAS: i < l}:
    sum {k in CAJAS} p[k] * x[k,i+1,j]
    <= sum {k in CAJAS} p[k] * x[k,i,j];

end;
