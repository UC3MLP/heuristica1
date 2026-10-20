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
    encabezado = lineas[0].split()
    l, h = int(encabezado[0]), int(encabezado[1])
    prioridades = [int(p) for p in lineas[1].split()]
    pesos = [float(w) for w in lineas[2].split()]
    capacidades = [float(g) for g in lineas[3].split()]

    n = len(prioridades) # vemos prioridades, lado, niveles, y n real de cajas
    if l < 1 or h < 1 or n < 1 or n > h * l * l or len(pesos) != n or len(capacidades) != n or any(p < 1 for p in prioridades):
        sys.exit("Entrada no valida")

    M_val = max(prioridades) + 1000 # Big-M adaptativo

    # generamos .dat MathProg
    with datos.open("w") as f:
        f.write(f"data;\nparam l := {l};\nparam h := {h};\nparam n := {n};\nparam M := {M_val};\n") # cabecera
        f.write("param p :=\n")
        for k, p in enumerate(prioridades, 1):
            f.write(f"{k} {p}\n")
        f.write(";\nparam w :=\n")
        for k, w in enumerate(pesos, 1):
            f.write(f"{k} {w}\n")
        f.write(";\nparam gamma :=\n")
        for k, g in enumerate(capacidades, 1):
            f.write(f"{k} {g}\n")
        f.write(";\nend;\n")

    # GLPK!
    with TemporaryDirectory() as carpeta:
        informe = Path(carpeta) / "resultado.txt"
        proceso = subprocess.run(["glpsol", "-m", str(modelo), "-d", str(datos), "-o", str(informe)], capture_output=True, text=True)
        if proceso.returncode != 0: # error
            sys.exit(proceso.stderr or proceso.stdout)
        texto = informe.read_text()
    if "INTEGER OPTIMAL" not in texto: # no int óptimo !!
        sys.exit("GLPK no ha encontrado una solucion entera optima")

    # recuperamos cajas
    pallet = [[[0] * l for _ in range(l)] for _ in range(h)] # matriz 3d
    for k, s, i, j, valor in re.findall(r"^\s*\d+\s+x\[(\d+),(\d+),(\d+),(\d+)\]\s+\*?\s*([01])(?=\s|$)", texto, re.MULTILINE):
        # extraemos:
        # k: id caja, s: nivel, i: fila, j: columna, valor: 0/1
        if valor == "1":
            pallet[int(s)-1][int(i)-1][int(j)-1] = prioridades[int(k)-1] # colocamos

    # num var, restr, coste medio
    coste = sum(i * pallet[s][i][j] for s in range(h) for i in range(l) for j in range(l) if pallet[s][i][j] > 0) / n
    num_vars = n * h * l * l
    num_restr = n + (h * l * l) + ((h - 1) * l * l) + (h * (l - 1) * l) + ((h - 1) * l * l)
    print(f"{num_vars} {num_restr} {coste:.10g}")

    # guardo distr
    salida = datos.with_suffix(".sol.txt")
    with salida.open("w") as f:
        for s in range(h):
            f.write(f"--- Nivel {s+1} ---\n")
            for i in range(l-1, -1, -1):
                fila_str = [str(val) if val > 0 else "." for val in pallet[s][i]]
                f.write(" ".join(fila_str) + "\n")
            f.write("\n")


if __name__ == "__main__":
    main()