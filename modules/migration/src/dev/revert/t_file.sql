-- Revert t_file

BEGIN;

DROP TABLE IF EXISTS my_yacht.file CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.file_id_seq CASCADE;

COMMIT;
