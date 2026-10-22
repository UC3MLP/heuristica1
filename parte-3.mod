/* ==============================================================================
   PARTE 3: Optimización de pallets incompletos (parte-3.mod) con Big-M
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
var c {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}, >= 0;       /* coste en la posición trasera i del nivel s */

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

/* 7. CÁLCULO DEL COSTE CON BIG-M (3 desigualdades para encajonar c) */

/* 7a. Si la celda de atrás (i) está vacía (o=0), fuerza c = 0 */
s.t. CosteMaxAtras {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] <= Pmax * o[i,j,s];

/* 7b. c nunca puede ser mayor que la prioridad real de la caja de delante (i+1) */
s.t. CosteMaxDelante {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] <= sum {k in CAJAS} p[k] * x[k,i+1,j,s];

/* 7c. Si la celda de atrás (i) tiene caja (o=1), c debe ser al menos la prioridad de delante */
s.t. CosteMinAtras {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    c[i,j,s] >= sum {k in CAJAS} p[k] * x[k,i+1,j,s] - Pmax * (1 - o[i,j,s]);

end;