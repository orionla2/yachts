-- Verify t_additional

BEGIN;

SELECT * FROM my_yacht.additional WHERE FALSE;

ROLLBACK;
