#!/usr/bin/env bash
# Parte 3: recovery. Apaga os dois bancos e os restaura a partir do backup completo.
# Argumentos: opções de conexão do mysql (ex.: -h 127.0.0.1 -u root -p).
set -euo pipefail
cd "$(dirname "$0")"
mysql "$@" -e "DROP DATABASE IF EXISTS ecommerce; DROP DATABASE IF EXISTS relatorios;"
mysql --default-character-set=utf8mb4 "$@" < backup/ecommerce_relatorios.sql
echo "restaurado a partir de backup/ecommerce_relatorios.sql"
