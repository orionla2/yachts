-- Verify t_yacht

BEGIN;

SELECT * FROM my_yacht.yacht WHERE FALSE;

ROLLBACK;
