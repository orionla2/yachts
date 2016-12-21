-- Verify schema_pure

BEGIN;

SELECT pg_catalog.has_schema_privilege('my_yacht', 'usage');
SELECT pg_catalog.has_schema_privilege('auth', 'usage');

ROLLBACK;
