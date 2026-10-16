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
        sys.exit("Uso: ./sol-1.py entrada.in datos.dat")
    entrada, datos = ruta(sys.argv[1]), ruta(sys.argv[2])
    modelo = Path(__file__).resolve().parent / "parte-1.mod" # rutas guardadas

    lineas = entrada.read_text().splitlines()
    l = int(lineas[0])
    prioridades = [int(p) for p in lineas[1].split()]
    n = l * l   # vemos prioridades, lado, y n de cajas
    if l < 1 or len(prioridades) != n or any(p < 1 for p in prioridades):   # si l neg, o prioridades distinto a n, o prioridad no entera pos
        sys.exit("Entrada no valida")

    # generamos .dat MathProg
    with datos.open("w") as f:
        f.write(f"data;\nparam l := {l};\nparam n := {n};\nparam p :=\n")   # cabecera
        for k, p in enumerate(prioridades, 1):  # creamos tablita
            f.write(f"{k} {p}\n")
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

    # recuperamos cajas
    pallet = [[0] * l for _ in range(l)]    # matriz
    for k, i, j, valor in re.findall(r"^\s*\d+\s+x\[(\d+),(\d+),(\d+)\]\s+\*?\s*([01])(?=\s|$)", texto, re.MULTILINE):
        # extraemos:
        # k: id caja, i: fila, j: columna, valor: 0/1
        if valor == "1":
            pallet[int(i)-1][int(j)-1] = prioridades[int(k)-1]  # colocamos
    if any(p == 0 for fila in pallet for p in fila):    # si 0
        sys.exit("No se pudo leer la distribucion de GLPK")

    # num var, restr, coste medio
    coste = sum(i * sum(pallet[i]) for i in range(l)) / n
    print(f"{n*l*l} {2*n + l*(l-1)} {coste:.10g}")
    # guardo distr
    salida = datos.with_suffix(".sol.txt")
    with salida.open("w") as f:
        for i in range(l-1, -1, -1):
            f.write(" ".join(map(str, pallet[i])) + "\n")


if __name__ == "__main__":
    main()
