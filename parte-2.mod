/* p2: cajas CON NIVELES */

param l, integer, >= 1;
param h, integer, >= 1;
param n, integer, >= 1;
set CAJAS := 1..n;
set NIVELES := 1..h;
set FILAS := 1..l;
set COLUMNAS := 1..l;
param p {k in CAJAS}, integer, >= 1;
param w {k in CAJAS}, >= 0;
param gamma {k in CAJAS}, >= 0;

/* x[k,s,i,j] -> orden: k (caja), s (nivel), i (fila), j (columna) */
var x {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}, binary;

/* FUNC OBJ: coste medio */
minimize CosteMedio:
    (1/n) * sum {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}
        (i-1) * p[k] * x[k,s,i,j];

/* RESTR: una pos por caja */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {s in NIVELES, i in FILAS, j in COLUMNAS} x[k,s,i,j] = 1;

/* RESTR: una caja por pos */
s.t. UnaCajaPorPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,s,i,j] = 1;

/* RESTR: prioridades ordenadas */
s.t. OrdenPrioridades {s in NIVELES, i in FILAS, j in COLUMNAS: i < l}:
    sum {k in CAJAS} p[k] * x[k,s,i+1,j]
    <= sum {k in CAJAS} p[k] * x[k,s,i,j];

/* RESTR: capacidad de carga */
s.t. CapacidadCarga {s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k_sup in CAJAS, s_sup in NIVELES: s_sup > s} w[k_sup] * x[k_sup,s_sup,i,j]
    <= sum {k in CAJAS} gamma[k] * x[k,s,i,j];

/* RESTR: no cajas flotantes */
s.t. Flotacion {i in FILAS, j in COLUMNAS, s in NIVELES: s < h}:
    sum {k in CAJAS} x[k,s+1,i,j] <= sum {k in CAJAS} x[k,s,i,j];

end;