-- Verify t_yacht_description

BEGIN;

SELECT * FROM my_yacht.yacht_description WHERE FALSE;

ROLLBACK;
