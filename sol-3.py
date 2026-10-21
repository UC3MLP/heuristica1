#!/usr/bin/env python3

import sys
import subprocess
import os
import re


def leer_fichero_in(ruta_in):
    with open(ruta_in, 'r') as f:
        lineas = [linea.strip() for linea in f if linea.strip()]

    partes_dim = lineas[0].split()
    l = int(partes_dim[0])
    h = int(partes_dim[1])

    prioridades = list(map(int, lineas[1].split()))
    pesos = list(map(int, lineas[2].split()))
    capacidades = list(map(int, lineas[3].split()))

    n = len(prioridades)

    return l, h, n, prioridades, pesos, capacidades


def generar_fichero_dat(ruta_dat, l, h, n, prioridades, pesos, capacidades):
    with open(ruta_dat, 'w') as f:
        f.write(f"param l := {l};\n")
        f.write(f"param h := {h};\n")
        f.write(f"param n := {n};\n\n")

        f.write("param p :=\n")
        for idx, val in enumerate(prioridades, 1):
            f.write(f"  {idx} {val}\n")
        f.write(";\n\n")

        f.write("param w :=\n")
        for idx, val in enumerate(pesos, 1):
            f.write(f"  {idx} {val}\n")
        f.write(";\n\n")

        f.write("param gamma :=\n")
        for idx, val in enumerate(capacidades, 1):
            f.write(f"  {idx} {val}\n")
        f.write(";\n")


def parsear_solucion_glpk(ruta_sol_glpk, l, h):
    pallet = [[[0 for _ in range(l)] for _ in range(l)] for _ in range(h)]

    num_vars = 0
    num_restrs = 0
    obj_val = 0.0

    with open(ruta_sol_glpk, 'r') as f:
        lineas = f.readlines()

    for line in lineas:
        if "Rows:" in line:
            m = re.search(r'Rows:\s+(\d+)', line)
            if m: num_restrs = int(m.group(1))
        elif "Columns:" in line:
            m = re.search(r'Columns:\s+(\d+)', line)
            if m: num_vars = int(m.group(1))
        elif "Objective:" in line:
            m = re.search(r'Objective:\s+\w+\s+=\s+([\d\.\+eE-]+)', line)
            if m: obj_val = float(m.group(1))

        # Parseo de las variables binarias x[k,s,i,j] = 1
        if line.strip().startswith("x["):
            partes = line.split()
            var_name = partes[1]
            # En GLPK la columna del valor de la variable suele ser la 3ª (índice 3 o 2)
            val = float(partes[3]) if len(partes) > 3 else float(partes[2])

            if abs(val - 1.0) < 1e-4:
                m_var = re.search(r'x\[(\d+),(\d+),(\d+),(\d+)\]', var_name)
                if m_var:
                    k = int(m_var.group(1))
                    s = int(m_var.group(2)) - 1
                    i = int(m_var.group(3)) - 1
                    j = int(m_var.group(4)) - 1
                    pallet[s][i][j] = k

    return pallet, num_vars, num_restrs, obj_val


def main():
    if len(sys.argv) < 3:
        print("Uso: ./sol-3.py <fichero-entrada> <fichero-salida.dat>")
        sys.exit(1)

    fichero_in = sys.argv[1]
    fichero_dat = sys.argv[2]

    dir_script = os.path.dirname(os.path.abspath(__file__))
    fichero_mod = os.path.join(dir_script, "parte-3.mod")

    nombre_base = os.path.splitext(fichero_in)[0]
    fichero_sol_txt = f"{nombre_base}.sol.txt"
    fichero_sol_glpk = f"{nombre_base}.glpksol"

    l, h, n, prioridades, pesos, capacidades = leer_fichero_in(fichero_in)

    # 1. Generar archivo .dat
    generar_fichero_dat(fichero_dat, l, h, n, prioridades, pesos, capacidades)

    # 2. Ejecutar Solver GLPK
    cmd = [
        "glpsol",
        "--mod", fichero_mod,
        "--data", fichero_dat,
        "-o", fichero_sol_glpk
    ]

    resultado = subprocess.run(cmd, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True)
    if resultado.returncode != 0:
        print("Error ejecutando glpsol:")
        print(resultado.stderr)
        sys.exit(1)

    # 3. Extraer resultados
    pallet, num_vars, num_restrs, coste_medio = parsear_solucion_glpk(
        fichero_sol_glpk, l, h)

    # 4. Imprimir la salida estándar requerida: <vars> <restrs> <obj>
    print(f"{num_vars} {num_restrs} {coste_medio:.2f}")

    # 5. Generar archivo gráfico de salida con la disposición final
    with open(fichero_sol_txt, 'w') as f_sol:
        f_sol.write(f"Coste Medio: {coste_medio:.2f}\n\n")

        for s in range(h):
            f_sol.write(f"-- Nivel {s + 1} --\n")
            for i in reversed(range(l)):
                fila_str = []
                for j in range(l):
                    val = pallet[s][i][j]
                    fila_str.append(f"{val:2d}" if val > 0 else " .")
                f_sol.write(" ".join(fila_str) + "\n")
            f_sol.write("\n")

    # Limpieza de archivo temporal de GLPK
    if os.path.exists(fichero_sol_glpk):
        os.remove(fichero_sol_glpk)


if __name__ == "__main__":
    main()