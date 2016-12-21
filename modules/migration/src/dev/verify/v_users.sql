-- Verify v_users

BEGIN;

SELECT * FROM my_yacht.users WHERE FALSE;

ROLLBACK;
