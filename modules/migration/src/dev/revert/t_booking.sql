-- Revert t_booking

BEGIN;

DROP TABLE IF EXISTS my_yacht.booking CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.booking_id_seq CASCADE;

COMMIT;
