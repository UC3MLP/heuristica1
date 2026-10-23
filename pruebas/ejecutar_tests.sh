#!/usr/bin/env bash
# Ejecutar desde cualquier ubicacion tras copiar la carpeta tests a la raiz del proyecto.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
for f in tests/p1_*.in; do
  echo "==== PARTE 1: $f ===="
  /usr/bin/time -f 'Tiempo real (s): %e' python3 sol-1.py "$f" "${f%.in}.dat"
done
for f in tests/p4_*.in; do
  echo "==== PARTE 4: $f ===="
  /usr/bin/time -f 'Tiempo real (s): %e' python3 sol-4.py "$f" "${f%.in}.dat"
done
