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

    lineas = entrada.read_text().splitlines()
    l, h = [int(v) for v in lineas[0].split()]
    prioridades = [int(p) for p in lineas[1].split()]
    pesos = [int(w) for w in lineas[2].split()]
    capacidades = [int(g) for g in lineas[3].split()]
    n = len(prioridades)   # vemos l, h, listas y n de cajas

    if l < 1 or h < 1 or n < 1 or n > h * l * l or len(pesos) != n or len(capacidades) != n:   # validaciones
        sys.exit("Entrada no valida")

    # generamos .dat MathProg
    with datos.open("w") as f:
        f.write(f"data;\nparam l := {l};\nparam h := {h};\nparam n := {n};\n")   # cabecera
        f.write("param p :=\n")
        for k, val in enumerate(prioridades, 1):
            f.write(f"{k} {val}\n")
        f.write(";\nparam w :=\n")
        for k, val in enumerate(pesos, 1):
            f.write(f"{k} {val}\n")
        f.write(";\nparam g :=\n")
        for k, val in enumerate(capacidades, 1):
            f.write(f"{k} {val}\n")
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

    # recuperamos cajas en matriz 3D (nivel, fila, col)
    pallet = [[[0] * l for _ in range(l)] for _ in range(h)]
    for k, i, j, s, valor in re.findall(r"^\s*\d+\s+x\[(\d+),(\d+),(\d+),(\d+)\]\s+\*?\s*([01])(?=\s|$)", texto, re.MULTILINE):
        # extraemos:
        # k: id caja, i: fila, j: col, s: nivel, valor: 0/1
        if valor == "1":
            pallet[int(s)-1][int(i)-1][int(j)-1] = prioridades[int(k)-1]  # colocamos

    # extraer num variables y restricciones creadas desde el texto de GLPK
    filas_match = re.search(r"Rows:\s+(\d+)", texto)
    cols_match = re.search(r"Columns:\s+(\d+)", texto)
    num_restr = int(filas_match.group(1)) if filas_match else 0
    num_vars = int(cols_match.group(1)) if cols_match else 0

    # calcular coste medio (SOLO si la posición trasera TIENE CAJA)
    coste_total = 0
    for s in range(h):
        for j in range(l):
            for i in range(l - 1):
                if pallet[s][i][j] != 0:  # Si atras hay caja real
                    coste_total += sum(pallet[s][i_p][j] for i_p in range(i + 1, l))
    coste_medio = coste_total / n

    # num var, restr, coste medio
    print(f"{num_vars} {num_restr} {coste_medio:.10g}")

    # guardo distr en salida
    salida = datos.with_suffix(".sol.txt")
    with salida.open("w") as f:
        for s in range(h):
            f.write(f"--- Nivel {s+1} ---\n")
            for i in range(l-1, -1, -1):
                f.write(" ".join(map(str, pallet[s][i])) + "\n")


if __name__ == "__main__":
    main()