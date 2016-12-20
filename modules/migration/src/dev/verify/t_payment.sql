-- Verify t_payment

BEGIN;

SELECT * FROM my_yacht.payment WHERE FALSE;

ROLLBACK;
