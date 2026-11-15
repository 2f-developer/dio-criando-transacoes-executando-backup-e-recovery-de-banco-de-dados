#!/usr/bin/env bash
# Roda as três partes e testa o recovery a partir do backup versionado em backup/.
# Os argumentos vão para o cliente mysql (ex.: -h 127.0.0.1 -u root -p).
set -euo pipefail
cd "$(dirname "$0")"
roda() {
  local saida
  if ! saida=$(mysql --default-character-set=utf8mb4 "$@" 2>&1); then echo "$saida"; exit 1; fi
  grep -E '^ok|passaram|FALHOU' <<< "$saida" || true
  if grep -q FALHOU <<< "$saida"; then exit 1; fi
}
for arquivo in sql/01_schema.sql sql/02_transacao.sql sql/03_procedure_transacao.sql sql/04_recursos_extras.sql tests/verificacoes.sql; do
  echo "== $arquivo"
  roda "$@" < "$arquivo"
done
echo "== recovery"
./recovery.sh "$@"
roda "$@" < tests/pos_recovery.sql
