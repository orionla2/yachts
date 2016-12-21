-- Verify t_extras

BEGIN;

SELECT * FROM my_yacht.extras WHERE FALSE;

ROLLBACK;
