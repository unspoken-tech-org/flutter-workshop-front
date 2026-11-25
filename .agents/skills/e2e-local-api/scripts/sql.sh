#!/usr/bin/env bash
# sql.sh "<query>"        runs one statement in the synthetic E2E database
#                         (container e2e-local-db), unaligned output
# sql.sh --schema [TABLE] columns and types of TABLE (or the list of tables),
#                         so queries never guess column names
# Only for the isolated database started by up.sh; never PRD, QA or dev.
set -u
PSQL=(docker exec -i e2e-local-db psql -U workshop_synthetic -d workshop_synthetic -v ON_ERROR_STOP=1 -tA)
case "${1:-}" in
  "") echo "usage: sql.sh \"<query>\" | sql.sh --schema [table]"; exit 2 ;;
  --schema)
    if [ -n "${2:-}" ]; then
      "${PSQL[@]}" -F ' ' -v t="$2" <<'SQL'
select column_name, data_type, case when is_nullable = 'NO' then 'not null' else '' end
from information_schema.columns
where table_schema = 'public' and table_name = :'t'
order by ordinal_position;
SQL
    else
      "${PSQL[@]}" -c "select table_name from information_schema.tables where table_schema = 'public' order by 1"
    fi ;;
  *) "${PSQL[@]}" -c "$1" ;;
esac
