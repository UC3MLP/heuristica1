#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

# devolver ruta del fichero
def ruta(nombre):
    p = Path(nombre)
    if not p.is_absolute() and p.parent == Path("."):
        return Path(__file__).resolve().parent / p
    return p.resolve()


def main():
    if len(sys.argv) != 3:  # comprobamos que se pasen 2 argumentos
        sys.exit("Uso: ./sol-4.py entrada.in datos.dat")
    
    entrada, datos = ruta(sys.argv[1]), ruta(sys.argv[2])  # rutas
    modelo = Path(__file__).resolve().parent / "parte-4.mod"  # rutas
    # leemos lado, niveles, coste del pallet y datos de cada caja
    lineas = [linea.strip() for linea in entrada.read_text().splitlines()
              if linea.strip()]
    if len(lineas) != 4 or len(lineas[0].split()) != 3:  # formato de entrada incorrecto
        sys.exit("Entrada no valida")
    
    l, h = map(int, lineas[0].split()[:2])
    precio = float(lineas[0].split()[2])
    prioridades = [int(p) for p in lineas[1].split()]
    pesos = [int(w) for w in lineas[2].split()]
    capacidades = [int(g) for g in lineas[3].split()]
    n = len(prioridades)  # numero de cajas, ahora puede ser menor que h*l*l
    # comprobamos que haya datos validos y que todas las cajas tengan peso y capacidad
    if (l < 1 or h < 1 or n < 1 or precio < 0 or
        len(pesos) != n or len(capacidades) != n or
        any(p < 1 for p in prioridades) or
        any(w < 0 for w in pesos) or any(g < 0 for g in capacidades)):
        sys.exit("Entrada no valida")
    
    # generamos el .dat
    with datos.open("w") as f:
        f.write(f"data;\nparam l := {l};\nparam h := {h};\n"
                f"param n := {n};\nparam precio := {precio};\n\n")
        # escribimos la tabla de prioridades, pesos y capacidades
        for nombre, valores in (("p", prioridades), ("w", pesos),
                                ("gamma", capacidades)):
            f.write(f"param {nombre} :=\n")
            for k, valor in enumerate(valores, 1):
                f.write(f"{k} {valor}\n")
            f.write(";\n\n")
        f.write("end;\n")
    # GLPK! resolvemos el modelo con el .dat

    with TemporaryDirectory() as carpeta:
        informe = Path(carpeta) / "resultado.txt"  # informe temporal de GLPK
        proceso = subprocess.run(["glpsol", "-m", str(modelo), "-d", str(datos), "-o", str(informe)], capture_output=True, text=True)
        if proceso.returncode != 0:  # error al ejecutar GLPK
            sys.exit(proceso.stderr or proceso.stdout)
        texto = informe.read_text()
    if "INTEGER OPTIMAL" not in texto:  # no ha encontrado optimo entero
        sys.exit("GLPK no ha encontrado una solucion entera optima")
    # recuperamos las cajas: pallet, nivel, fila y columna
    pallets = [[[[0] * l for _ in range(l)] for _ in range(h)]
               for _ in range(n)]
    # buscamos las variables x[k,b,s,i,j] con valor 1 en el informe
    patron = r"x\[(\d+),(\d+),(\d+),(\d+),(\d+)\]\s+\*?\s*1(?=\s|$)"

    for k, b, s, i, j in re.findall(patron, texto):
        pallets[int(b)-1][int(s)-1][int(i)-1][int(j)-1] = int(k)  # ponemos la caja k
    # comprobamos que se han recuperado todas las cajas, sin repetir ninguna
    cajas_colocadas = sorted(k for pb in pallets for nivel in pb for fila in nivel for k in fila if k != 0)
    if cajas_colocadas != list(range(1, n+1)):
        sys.exit("No se pudo leer la distribucion de GLPK")

    # num variables, restricciones y coste total, segun informe GLPK
    m_vars = re.search(r"Columns:\s+(\d+)", texto)
    m_rows = re.search(r"Rows:\s+(\d+)", texto)
    m_obj = re.search(r"Objective:\s+\w+\s+=\s+([\d.\+eE-]+)", texto)
    if not m_vars or not m_rows or not m_obj:
        sys.exit("No se pudieron leer los resultados de GLPK")
    num_vars = m_vars.group(1)
    num_restrs = m_rows.group(1)
    coste_total = float(m_obj.group(1))
    print(f"{num_vars} {num_restrs} {coste_total:.10g}")  # unica linea exigida
    # guardamos la distribucion de cada pallet y nivel
    usados = [b for b, pb in enumerate(pallets, 1)  # pallets con alguna caja
              if any(k for nivel in pb for fila in nivel for k in fila)]

    salida = datos.with_suffix(".sol.txt")
    with salida.open("w") as f:
        f.write(f"Coste Total: {coste_total:.2f}\n")
        f.write(f"Pallets utilizados: {len(usados)}\n\n")
        for b in usados:
            f.write(f"=== Pallet {b} ===\n")
            for s, nivel in enumerate(pallets[b-1], 1):
                f.write(f"-- Nivel {s} --\n")
                for i in range(l-1, -1, -1):  # de arriba (acceso) a abajo
                    fila_str = [f"{prioridades[k-1]:2d}" if k else " ." for k in nivel[i]]
                    f.write(" ".join(fila_str) + "\n")
                f.write("\n")
                

if __name__ == "__main__":
    main()
