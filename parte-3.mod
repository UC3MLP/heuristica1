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
var y {k in CAJAS, i in FILAS, j in COLUMNAS, s in NIVELES: i < l}, binary; /* y[k,i,j,s] = 1 si la caja k esta en i+1 Y la fila i esta ocupada */

/* FUNCIÓN OBJETIVO: Coste medio directo exacto */
minimize CosteMedio:
    (1/n) * sum {s in NIVELES, j in COLUMNAS, i in FILAS, k in CAJAS: i < l}
        p[k] * y[k, i, j, s];

/* RESTRICCIONES */

/* 1. Cada caja debe colocarse exactamente en una posición */
s.t. UnaPosicionPorCaja {k in CAJAS}:
    sum {i in FILAS, j in COLUMNAS, s in NIVELES} x[k,i,j,s] = 1;

/* 2. Una caja como máximo por posición */
s.t. UnaCajaPorPosicion {i in FILAS, j in COLUMNAS, s in NIVELES}:
    sum {k in CAJAS} x[k,i,j,s] <= 1;

/* 3. Flotación: no puede haber cajas en el aire */
s.t. Flotacion {i in FILAS, j in COLUMNAS, s in NIVELES: s < h}:
    sum {k in CAJAS} x[k,i,j,s+1] <= sum {k in CAJAS} x[k,i,j,s];

/* 4. Capacidad de carga */
s.t. Capacidad {i in FILAS, j in COLUMNAS, s in NIVELES}:
    sum {s_prime in NIVELES, k in CAJAS: s_prime > s} w[k] * x[k,i,j,s_prime]
    <= sum {k in CAJAS} g[k] * x[k,i,j,s];

/* 5. Sin huecos intermedios (ocupación contigua de delante a atrás) */
s.t. SinHuecosIntermedios {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    sum {k in CAJAS} x[k, i, j, s] <= sum {k in CAJAS} x[k, i+1, j, s];

/* 6. Orden de prioridades: p_delante <= p_atras (si en i hay caja) */
s.t. OrdenPrioridades {i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    sum {k in CAJAS} p[k] * x[k,i+1,j,s]
    <= sum {k in CAJAS} p[k] * x[k,i,j,s] + Pmax * (1 - sum {k in CAJAS} x[k,i,j,s]);

/* 7. LINEALIZACIÓN EXACTA DE Y (y[k,i,j,s] = x[k,i+1,j,s] AND fila_i_ocupada) */

/* 7a. y[k,i,j,s] solo puede valer 1 si la caja k está efectivamente delante en i+1 */
s.t. ActivaY_CajaDelante {k in CAJAS, i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    y[k, i, j, s] <= x[k, i+1, j, s];

/* 7b. y[k,i,j,s] solo puede valer 1 si en la fila de atrás (i) HAY una caja real */
s.t. ActivaY_CajaAtras {k in CAJAS, i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    y[k, i, j, s] <= sum {k_prime in CAJAS} x[k_prime, i, j, s];

/* 7c. Si la caja k está delante Y en atrás hay una caja real, y[k,i,j,s] DEBE valer 1 */
s.t. ActivaY_Ambas {k in CAJAS, i in FILAS, j in COLUMNAS, s in NIVELES: i < l}:
    y[k, i, j, s] >= x[k, i+1, j, s] + sum {k_prime in CAJAS} x[k_prime, i, j, s] - 1;

end;