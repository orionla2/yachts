-- Revert schema_pure

BEGIN;

DROP SCHEMA if exists auth cascade;
DROP SCHEMA if exists my_yacht cascade;

COMMIT;
