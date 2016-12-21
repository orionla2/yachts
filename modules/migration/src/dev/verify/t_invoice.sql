-- Verify t_invoice

BEGIN;

SELECT * FROM my_yacht.invoice WHERE FALSE;

ROLLBACK;
