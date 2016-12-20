-- Verify t_download

BEGIN;

SELECT * FROM my_yacht.download WHERE FALSE;

ROLLBACK;
