-- Revert t_packages

BEGIN;

DROP TABLE IF EXISTS my_yacht.packages CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.packages_id_seq CASCADE;

COMMIT;
