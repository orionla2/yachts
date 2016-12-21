-- Verify t_status

BEGIN;

SELECT * FROM my_yacht.status WHERE FALSE;

ROLLBACK;
