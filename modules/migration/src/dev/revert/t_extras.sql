-- Revert t_extras

BEGIN;

DROP TABLE IF EXISTS my_yacht.extras CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.extras_id_seq CASCADE;

COMMIT;
