-- Verify t_text_storage

BEGIN;

SELECT * FROM my_yacht.text_storage WHERE FALSE;

ROLLBACK;
