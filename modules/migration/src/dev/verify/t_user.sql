-- Verify t_user

BEGIN;

SELECT * FROM my_yacht.user WHERE FALSE;

ROLLBACK;
