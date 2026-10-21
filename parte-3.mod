/* parte-3.mod: Pallets incompletos */

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

/* FUNC. OBJ: Coste medio real de las n cajas */
minimize CosteMedio:
    (1/n) * sum {k in CAJAS, s in NIVELES, i in FILAS, j in COLUMNAS}
        (l - i) * p[k] * x[k,s,i,j];

/* RESTR: Cada caja debe asignarse a exactamente una posición */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {s in NIVELES, i in FILAS, j in COLUMNAS} x[k,s,i,j] = 1;

/* RESTR: Como máximo una caja por posición */
s.t. MaxUnaCajaPorPosicion {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k in CAJAS} x[k,s,i,j] <= 1;

/* RESTR: Gravedad / Soporte vertical */
s.t. FloatingBox {s in NIVELES, i in FILAS, j in COLUMNAS: s < h}:
    sum {k in CAJAS} x[k,s+1,i,j] <= sum {k in CAJAS} x[k,s,i,j];

/* RESTR: Contigüidad hacia la salida (evita huecos vacíos delante de una caja) */
s.t. ContiguidadSalida {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    sum {k in CAJAS} x[k,s,i,j] <= sum {k in CAJAS} x[k,s,i+1,j];

/* RESTR: Orden de prioridades en la misma columna */
s.t. OrdenPrioridades {s in NIVELES, j in COLUMNAS, i in FILAS: i < l}:
    sum {k in CAJAS} p[k] * x[k,s,i+1,j]
    <= sum {k in CAJAS} p[k] * x[k,s,i,j] + M * (1 - sum {k in CAJAS} x[k,s,i,j]);

/* RESTR: Capacidad de carga que soporta cada caja */
s.t. EmptyCapacity {s in NIVELES, i in FILAS, j in COLUMNAS}:
    sum {k_sup in CAJAS, s_sup in NIVELES: s_sup > s} w[k_sup] * x[k_sup,s_sup,i,j]
    <= sum {k in CAJAS} gamma[k] * x[k,s,i,j];

end;