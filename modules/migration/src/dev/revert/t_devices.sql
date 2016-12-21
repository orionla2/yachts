-- Revert t_devices

BEGIN;

DROP TABLE IF EXISTS my_yacht.devices CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.devices_id_seq CASCADE;

COMMIT;
