-- Verify extensions

BEGIN;

SELECT 1/count(*) FROM pg_extension WHERE extname = 'plpgsql';
SELECT 1/count(*) FROM pg_extension WHERE extname = 'pgcrypto';

ROLLBACK;
