/* ==============================================================================
   PARTE 3: Optimización de pallets incompletos (parte-3.mod)
   ============================================================================== */

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

/* VARIABLES DE DECISIÓN */
var x {k in CAJAS, i in FILAS, j in COLUMNAS, s in NIVELES}, binary; /* x[k,i,j,s] = 1 si caja k en (i,j,s) */
var o {i in FILAS, j in COLUMNAS, s in NIVELES}, binary;            /* o[i,j,s] = 1 si hay caja real en (i,j,s) */
var c {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}, >= 0;       /* coste en la posicion trasera i del nivel s */

/* FUNCIÓN OBJETIVO: Coste medio exacto */
minimize CosteMedio:
    (1/n) * sum {s in NIVELES, j in COLUMNAS, i in FILAS: i < l} c[i,j,s];

/* RESTRICCIONES */

/* 1. Cada caja debe colocarse exactamente en una posición */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {i in FILAS, j in COLUMNAS, s in NIVELES} x[k,i,j,s] = 1;

/* 2. Definición de ocupación de la celda */
s.t. DefOcupacion {i in FILAS, j in COLUMNAS, s in NIVELES}:
    o[i,j,s] = sum {k in CAJAS} x[k,i,j,s];

/* 3. Flotación: no puede haber cajas en el aire */
s.t. Flotacion {i in FILAS, j in COLUMNAS, s in NIVELES: s < h}:
    o[i,j,s+1] <= o[i,j,s];

/* 4. Capacidad de carga */
s.t. Capacidad {i in FILAS, j in COLUMNAS, s in NIVELES}:
    sum {s_prime in NIVELES, k in CAJAS: s_prime > s} w[k] * x[k,i,j,s_prime]
    <= sum {k in CAJAS} g[k] * x[k,i,j,s];

/* 5. Sin huecos intermedios (ocupación contigua de delante a atrás) */
s.t. SinHuecosIntermedios {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    o[i,j,s] <= o[i+1,j,s];

/* 6. Orden de prioridades: p_delante <= p_atras (Big-M) */
s.t. OrdenPrioridades {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    sum {k in CAJAS} p[k] * x[k,i+1,j,s]
    <= sum {k in CAJAS} p[k] * x[k,i,j,s] + Pmax * (1 - o[i,j,s]);

/* 7. CÁLCULO DEL COSTE POR CAJA EN DELANTE ACTIVADA POR ATRÁS */

/* 7a. El coste c de la celda i es la suma de las prioridades de delante activadas si en i hay caja */
s.t. DefCosteMax {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] >= sum {k in CAJAS} p[k] * x[k,i+1,j,s] + Pmax * (o[i,j,s] - 1);

/* 7b. Cota superior: fuerza c = 0 si en atras NO hay caja */
s.t. DefCosteCotaAtras {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] <= Pmax * o[i,j,s];

/* 7c. Cota superior: fuerza c <= prioridad de delante */
s.t. DefCosteCotaDelante {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] <= sum {k in CAJAS} p[k] * x[k,i+1,j,s];

end;