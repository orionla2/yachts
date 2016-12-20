-- Revert t_text_storage

BEGIN;

DROP TABLE IF EXISTS my_yacht.text_storage CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.text_storage_id_seq CASCADE;

COMMIT;
