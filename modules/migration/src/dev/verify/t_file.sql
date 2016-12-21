-- Verify t_file

BEGIN;

SELECT * FROM my_yacht.file WHERE FALSE;

ROLLBACK;
