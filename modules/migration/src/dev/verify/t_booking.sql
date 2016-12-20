-- Verify t_booking

BEGIN;

SELECT * FROM my_yacht.booking WHERE FALSE;

ROLLBACK;
