/* p3: pallets INCOMPLETOS */

param l, integer, >= 1;
param h, integer, >= 1;
param n, integer, >= 1;

set CAJAS := 1..n;
set FILAS := 1..l;
set COLUMNAS := 1..l;
set NIVELES := 1..h;

param p {k in CAJAS}, integer, >= 1;
param w {k in CAJAS}, integer, >= 0;
param g {k in CAJAS}, integer, >= 0;

param Pmax := max {k in CAJAS} p[k];

var x {k in CAJAS, i in FILAS, j in COLUMNAS, s in NIVELES}, binary; /* x[k,i,j,s] = 1 si caja k en (i,j,s) */
var o {i in FILAS, j in COLUMNAS, s in NIVELES}, binary;            /* o[i,j,s] = 1 si hay caja real en (i,j,s) */
var c {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}, >= 0;       /* coste en la posicion trasera i */

/* FUNC OBJ: coste medio */
minimize CosteMedio:
    (1/n) * sum {s in NIVELES, j in COLUMNAS, i in FILAS: i < l} c[i,j,s];

/* RESTR 1: una pos por caja */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {i in FILAS, j in COLUMNAS, s in NIVELES} x[k,i,j,s] = 1;

/* RESTR 2: definicion de ocupacion de posicion */
s.t. DefOcupacion {i in FILAS, j in COLUMNAS, s in NIVELES}:
    o[i,j,s] = sum {k in CAJAS} x[k,i,j,s];

/* RESTR 3: flotacion (no cajas en el aire) */
s.t. Flotacion {i in FILAS, j in COLUMNAS, s in NIVELES: s < h}:
    o[i,j,s+1] <= o[i,j,s];

/* RESTR 4: capacidad de carga */
s.t. Capacidad {i in FILAS, j in COLUMNAS, s in NIVELES}:
    sum {s_prime in NIVELES, k in CAJAS: s_prime > s} w[k] * x[k,i,j,s_prime]
    <= sum {k in CAJAS} g[k] * x[k,i,j,s];

/* RESTR 5: ocupacion sin huecos delante de una caja */
s.t. SinHuecosIntermedios {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    o[i,j,s] <= o[i+1,j,s];

/* RESTR 6: prioridades ordenadas (p_delante <= p_atras) */
s.t. OrdenPrioridades {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    sum {k in CAJAS} p[k] * x[k,i+1,j,s]
    <= sum {k in CAJAS} p[k] * x[k,i,j,s] + Pmax * (1 - o[i,j,s]);

/* RESTR 7a: c[i,j,s] debe ser al menos la prioridad de delante si atras hay caja */
s.t. ActivaCosteMin {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] >= sum {k in CAJAS} p[k] * x[k,i+1,j,s] - Pmax * (1 - o[i,j,s]);

/* RESTR 7b: c[i,j,s] no puede superar Pmax * o[i,j,s] (fuerza c = 0 si atras esta vacio) */
s.t. ActivaCosteMax {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] <= Pmax * o[i,j,s];

end;