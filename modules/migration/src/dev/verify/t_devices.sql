-- Verify t_devices

BEGIN;

SELECT * FROM my_yacht.devices WHERE FALSE;

ROLLBACK;
