-- Revert t_yacht_description

BEGIN;

DROP TABLE IF EXISTS my_yacht.yacht_description CASCADE;

COMMIT;
