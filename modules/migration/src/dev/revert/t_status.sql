-- Revert t_status

BEGIN;

DROP TABLE IF EXISTS my_yacht.status CASCADE;

COMMIT;
