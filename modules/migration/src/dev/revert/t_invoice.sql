-- Revert t_invoice

BEGIN;

DROP TABLE IF EXISTS my_yacht.invoice CASCADE;
DROP SEQUENCE IF EXISTS my_yacht.invoice_id_seq CASCADE;

COMMIT;
