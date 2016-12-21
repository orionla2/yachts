-- Verify t_packages

BEGIN;

SELECT * FROM my_yacht.packages WHERE FALSE;

ROLLBACK;
