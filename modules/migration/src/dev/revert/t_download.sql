-- Revert t_download

BEGIN;

DROP TABLE IF EXISTS my_yacht.download CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.download_id_seq CASCADE;
COMMIT;
