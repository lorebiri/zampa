#!/usr/bin/env bash
# Prova lo schema di Zampa su un Postgres locale (niente Docker, niente cloud).
#
# Prerequisiti: Postgres 15+ in esecuzione in locale, con un superutente.
#   brew install postgresql@16
#   export LC_ALL=en_US.UTF-8
#   initdb -D /percorso/pgdata -U postgres --auth=trust
#   pg_ctl -D /percorso/pgdata -o "-p 54329" -l /percorso/pg.log start
#   PGPORT=54329 supabase/tests/esegui.sh
#
# Cosa fa:
#   1. database nuovo: schema.sql eseguito DUE volte (deve essere rieseguibile),
#      poi i test di sicurezza;
#   2. database con lo schema precedente (versione 1, dal primo commit) e
#      qualche dato: migrazione 2026-11-10_sicurezza.sql, poi gli stessi test;
#   3. confronta la struttura dei due database: devono coincidere;
#   4. controlla che la migrazione coincida con la sezione 2 di schema.sql.
set -euo pipefail

cd "$(dirname "$0")/.."
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-postgres}"
if ! command -v psql >/dev/null && [ -x /opt/homebrew/opt/postgresql@16/bin/psql ]; then
  PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
fi
MIG=migrations/2026-11-10_sicurezza.sql
MIG2=migrations/2026-11-14_promemoria_web.sql
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export PGOPTIONS="-c client_min_messages=warning"
PSQL=(psql -X -q -v ON_ERROR_STOP=1)

nuovo_db() {
  dropdb --if-exists "$1"
  createdb "$1"
  "${PSQL[@]}" -d "$1" -f tests/00_supabase_simulato.sql >/dev/null
}

echo "== 1. Schema da zero (eseguito due volte) + test"
nuovo_db zampa_test_nuovo
"${PSQL[@]}" -d zampa_test_nuovo -f schema.sql >/dev/null
"${PSQL[@]}" -d zampa_test_nuovo -f schema.sql >/dev/null
"${PSQL[@]}" -d zampa_test_nuovo -f tests/01_sicurezza.sql
"${PSQL[@]}" -d zampa_test_nuovo -f tests/02_promemoria_web.sql

echo "== 2. Schema versione 1 + dati + migrazione (eseguita due volte) + test"
nuovo_db zampa_test_migrato
if git rev-parse --git-dir >/dev/null 2>&1 && git cat-file -e bf1e3fa:supabase/schema.sql 2>/dev/null; then
  git show bf1e3fa:supabase/schema.sql > "$TMP/schema_v1.sql"
  "${PSQL[@]}" -d zampa_test_migrato -f "$TMP/schema_v1.sql" >/dev/null
  "${PSQL[@]}" -d zampa_test_migrato >/dev/null <<'SQL'
insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000aa');
insert into public.dogs (id, owner, data)
  values ('vecchio', '00000000-0000-0000-0000-0000000000aa', '{"id":"vecchio"}');
insert into public.entries (id, dog_id, kind, data)
  values ('v1', 'vecchio', 'log', '{"id":"v1","dogId":"vecchio"}');
insert into public.invites (code, dog_id, created_by)
  values ('VECCHIO2', 'vecchio', '00000000-0000-0000-0000-0000000000aa');
SQL
  "${PSQL[@]}" -d zampa_test_migrato -f "$MIG" >/dev/null
  "${PSQL[@]}" -d zampa_test_migrato -f "$MIG" >/dev/null
  "${PSQL[@]}" -d zampa_test_migrato -f "$MIG2" >/dev/null
  "${PSQL[@]}" -d zampa_test_migrato -f "$MIG2" >/dev/null
  "${PSQL[@]}" -d zampa_test_migrato -Atc \
    "select 'dati della v1 conservati: ' || count(*) from public.entries where id = 'v1'"
  "${PSQL[@]}" -d zampa_test_migrato -c \
    "delete from auth.users where id = '00000000-0000-0000-0000-0000000000aa'" >/dev/null
  "${PSQL[@]}" -d zampa_test_migrato -f tests/01_sicurezza.sql | tail -1
  "${PSQL[@]}" -d zampa_test_migrato -f tests/02_promemoria_web.sql | tail -1

  echo "== 3. Struttura: schema da zero e schema migrato devono coincidere"
  for db in zampa_test_nuovo zampa_test_migrato; do
    pg_dump -s -n public -d "$db" | grep -v -e '^--' -e '^\\restrict' -e '^\\unrestrict' | sed '/^$/d' > "$TMP/$db.sql"
  done
  diff "$TMP/zampa_test_nuovo.sql" "$TMP/zampa_test_migrato.sql" || { echo "not ok - diverse"; exit 1; }
  echo "ok - identiche"
else
  echo "# saltato: serve il repository git con il primo commit (schema v1)"
fi

echo "== 4. La migrazione coincide con la sezione 2 di schema.sql"
sed -n '/^-- 2.1 Colonne/,/^commit;/p' schema.sql > "$TMP/a.sql"
sed -n '/^-- 2.1 Colonne/,/^commit;/p' "$MIG" > "$TMP/b.sql"
diff "$TMP/a.sql" "$TMP/b.sql" || { echo "not ok - diverse"; exit 1; }
echo "ok - coincidono"

echo "== 5. La migrazione dei promemoria coincide con la sezione 3 di schema.sql"
sed -n '/^-- 3.1 Tabelle/,/^commit;/p' schema.sql > "$TMP/a.sql"
sed -n '/^-- 3.1 Tabelle/,/^commit;/p' "$MIG2" > "$TMP/b.sql"
diff "$TMP/a.sql" "$TMP/b.sql" || { echo "not ok - diverse"; exit 1; }
echo "ok - coincidono"

dropdb zampa_test_nuovo
dropdb --if-exists zampa_test_migrato
echo "== Tutto verde"
