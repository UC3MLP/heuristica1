#!/usr/bin/env python3

import sys
import subprocess
import os


def leer_fichero_in(ruta_in):
    """
    Lee el fichero .in respetando la estructura oficial:
    Línea 1: <l> <h>
    Línea 2: prioridades [p1, ..., pn]
    Línea 3: pesos [w1, ..., wn]
    Línea 4: capacidades [gamma1, ..., gamman]
    """
    with open(ruta_in, 'r') as f:
        lineas = [linea.strip() for linea in f if linea.strip()]

    #Dimensiones del pallet
    partes_dim = lineas[0].split()
    l = int(partes_dim[0])  # Longitud del lado de la base
    h = int(partes_dim[1])  # Número de niveles

    #Prioridades, pesos, capacidades
    prioridades = list(map(int, lineas[1].split()))
    pesos = list(map(int, lineas[2].split()))
    capacidades = list(map(int, lineas[3].split()))

    n = len(prioridades)  # Cantidad real de cajas disponibles

    return l, h, n, prioridades, pesos, capacidades


def calcular_coste_medio_compacto(pallet, h, l, n):
    """
    Calcula el coste medio acumulando las prioridades de las cajas
    que están por delante (entre la caja actual y la salida i = l-1).
    """
    coste_acumulado = 0.0

    for s in range(h):
        for j in range(l):
            # Extraemos las cajas reales de arriba hacia abajo (hacia i = l-1)
            cajas_reales = [pallet[s][i][j] for i in reversed(range(l)) if
                            pallet[s][i][j] > 0]

            # Para cada caja, sumamos la prioridad de las cajas que están DELANTE de ella
            for idx in range(len(cajas_reales)):
                # cajas_reales[:idx] contiene las cajas entre la posición actual y la salida
                coste_acumulado += sum(cajas_reales[:idx])

    return coste_acumulado / n if n > 0 else 0.0


def main():
    if len(sys.argv) < 2:
        print("Uso: ./sol-3.py <fichero.in>")
        sys.exit(1)

    fichero_in = sys.argv[1]
    nombre_base = os.path.splitext(fichero_in)[0]
    fichero_sol = f"{nombre_base}.sol.txt"
    fichero_mod = "parte-3.mod"

    #Leer datos entrada
    l, h, n, prioridades, pesos, capacidades = leer_fichero_in(fichero_in)

    #Ejecutar GLPK (glpsol) --> archivo .mod
    cmd = [
        "glpsol",
        "--mod", fichero_mod,
        "--data", fichero_in,
        "--display", "solucion.out"]

    #archivo de log/display:
    resultado = subprocess.run(cmd, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True)
    if resultado.returncode != 0:
        print("Error ejecutando glpsol:")
        print(resultado.stderr)
        sys.exit(1)

    #matriz 3D 'pallet[s][i][j]' con los resultados de x[k,s,i,j] -->
    # inicializada con 0s para cajas vacias.
    pallet = [[[0 for _ in range(l)] for _ in range(l)] for _ in range(h)]

    #Calcular el Coste Medio compactado exacto en Python
    coste_medio = calcular_coste_medio_compacto(pallet, h, l, n)

    # Generar la salida requerida (.sol.txt y pantalla)
    print(f"Coste Medio: {coste_medio:.2f}")

    with open(fichero_sol, 'w') as f_sol:
        f_sol.write(f"Coste Medio: {coste_medio:.2f}\n\n")

        for s in range(h):
            f_sol.write(f"-- Nivel {s + 1} --\n")
            # Imprimimos de arriba hacia abajo
            for i in reversed(range(l)):
                fila_str = []
                for j in range(l):
                    val = pallet[s][i][j]
                    fila_str.append(str(val) if val > 0 else ".")
                f_sol.write(" ".join(fila_str) + "\n")
            f_sol.write("\n")

if __name__ == "__main__":
    main()