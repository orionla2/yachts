-- Revert t_additional

BEGIN;

DROP TABLE IF EXISTS my_yacht.additional CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.additional_id_seq CASCADE;

COMMIT;
