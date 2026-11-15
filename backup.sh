#!/usr/bin/env bash
# Parte 3: backup com mysqldump.
#   backup/ecommerce.sql             só o banco e-commerce
#   backup/ecommerce_relatorios.sql  os dois bancos, com procedures, eventos e triggers
# Argumentos: opções de conexão do mysqldump (ex.: -h 127.0.0.1 -u root -p).
set -euo pipefail
cd "$(dirname "$0")"
OPCOES=(--single-transaction --routines --events --triggers --default-character-set=utf8mb4 --set-gtid-purged=OFF)
mysqldump "${OPCOES[@]}" "$@" --databases ecommerce > backup/ecommerce.sql
mysqldump "${OPCOES[@]}" "$@" --databases ecommerce relatorios > backup/ecommerce_relatorios.sql
ls -l backup/
