-- Revert t_yacht

BEGIN;

DROP TABLE IF EXISTS my_yacht.yacht CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.yacht_id_seq CASCADE;

COMMIT;
