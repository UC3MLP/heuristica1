#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

# devolver ruta de fichero
def ruta(nombre):
    p = Path(nombre)
    if not p.is_absolute() and p.parent == Path("."):
        return Path(__file__).resolve().parent / p
    return p.resolve()

def main():
    if len(sys.argv) != 3: # si arg distinto de 3... comprobando 2 elementos
        sys.exit("Uso: ./sol-3.py entrada.in datos.dat")
    entrada, datos = ruta(sys.argv[1]), ruta(sys.argv[2])
    modelo = Path(__file__).resolve().parent / "parte-3.mod" # rutas guardadas

    lineas = [l.strip() for l in entrada.read_text().splitlines() if l.strip()]
    l, h = map(int, lineas[0].split())
    prioridades = [int(p) for p in lineas[1].split()]
    pesos = [int(w) for w in lineas[2].split()]
    capacidades = [int(g) for g in lineas[3].split()]
    n = len(prioridades)   # vemos prioridades, dimensiones, y n de cajas

    if l < 1 or h < 1 or n < 1 or n > h * l * l:
        sys.exit("Entrada no valida")

    # generamos .dat MathProg
    with datos.open("w") as f:
        f.write(f"data;\nparam l := {l};\nparam h := {h};\nparam n := {n};\n\n")
        f.write("param p :=\n")
        for k, p in enumerate(prioridades, 1):
            f.write(f"{k} {p}\n")
        f.write(";\n\nparam w :=\n")
        for k, w in enumerate(pesos, 1):
            f.write(f"{k} {w}\n")
        f.write(";\n\nparam gamma :=\n")
        for k, g in enumerate(capacidades, 1):
            f.write(f"{k} {g}\n")
        f.write(";\nend;\n")

    # GLPK!
    with TemporaryDirectory() as carpeta:
        informe = Path(carpeta) / "resultado.txt"
        proceso = subprocess.run(["glpsol", "-m", str(modelo), "-d", str(datos), "-o", str(informe)], capture_output=True, text=True)
        if proceso.returncode != 0:     # error
            sys.exit(proceso.stderr or proceso.stdout)
        texto = informe.read_text()
    if "INTEGER OPTIMAL" not in texto:  # no int óptimo !!
        sys.exit("GLPK no ha encontrado una solucion entera optima")

    # recuperamos cajas y estadisticas de GLPK
    pallet = [[[0] * l for _ in range(l)] for _ in range(h)]   # matriz 3D
    for k, s, i, j, valor in re.findall(r"^\s*\d+\s+x\[(\d+),(\d+),(\d+),(\d+)\]\s+\*?\s*([01])(?=\s|$)", texto, re.MULTILINE):
        if valor == "1":
            pallet[int(s)-1][int(i)-1][int(j)-1] = prioridades[int(k)-1]  # colocamos prioridad

    # parseo de num vars, restrs, y coste objetivo
    m_vars = re.search(r"Columns:\s+(\d+)", texto)
    m_rows = re.search(r"Rows:\s+(\d+)", texto)
    m_obj = re.search(r"Objective:\s+\w+\s+=\s+([\d\.\+eE-]+)", texto)

    num_vars = m_vars.group(1) if m_vars else "0"
    num_restrs = m_rows.group(1) if m_rows else "0"
    coste_obj = float(m_obj.group(1)) if m_obj else 0.0

    # num var, restr, coste medio
    print(f"{num_vars} {num_restrs} {coste_obj:.10g}")

    # guardo distr (.sol.txt)
    salida = datos.with_suffix(".sol.txt")
    with salida.open("w") as f:
        f.write(f"Coste Medio: {coste_obj:.2f}\n\n")
        for s in range(h):
            f.write(f"-- Nivel {s + 1} --\n")
            for i in range(l-1, -1, -1):
                fila_str = [str(val) if val > 0 else "." for val in pallet[s][i]]
                f.write(" ".join(fila_str) + "\n")
            f.write("\n")

if __name__ == "__main__":
    main()